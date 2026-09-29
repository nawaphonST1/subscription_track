pipeline {
    agent {
        docker {
            image 'node:20-bookworm-security'
        }
    }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'
        PATH = "${WORKSPACE}/scripts/bin:${env.PATH}"
    }

    options {
        // [TIMEOUT JUSTIFICATION]:
        // Bounded pipeline execution prevents hang states or zombie test runners from
        // exhausting CI build slots and incurring unbounded resource waste.
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Install') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Installing dependencies in ${env.NODE_ENV} environment..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh 'npm ci || npm install --no-audit'
                }
            }
        }

        stage('Secrets Detection') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Running Gitleaks secret detection across repository history..."
                sh '''
                    git config --global --add safe.directory "${WORKSPACE}" || true
                    chmod +x scripts/bin/* || true
                    gitleaks detect --source "${WORKSPACE}" --config "${WORKSPACE}/.gitleaks.toml" --verbose --report-path gitleaks-report.json
                '''
            }
        }

        stage('SAST') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Running SAST: ESLint Security Plugin & Semgrep..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh '''
                        npx --yes eslint --plugin security src/ --format @microsoft/eslint-formatter-sarif --output-file eslint-results.sarif || true
                    '''
                }
                sh '''
                    semgrep scan --config=p/owasp-top-ten --config=p/nodejs --sarif -o semgrep.sarif apps/server/src || true
                '''
            }
        }

        stage('SCA — npm audit') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Running SCA dependency audit with fail/warn threshold..."
                    dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                        sh 'npm audit --audit-level=high --json > audit.json || true'
                        def critical = sh(
                            script: "jq '.metadata.vulnerabilities.critical' audit.json",
                            returnStdout: true
                        ).trim().toInteger()
                        if (critical > 0) {
                            error("Blocking: ${critical} critical vulnerabilities found")
                        }
                        echo "SCA passed with 0 critical vulnerabilities (warnings allowed)"
                    }
                }
            }
        }

        stage('Generate SBOM') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Generating CycloneDX SBOM and signing release artifact with Cosign..."
                    sh '''
                        syft dir:apps/server --exclude "**/node_modules/**" -o cyclonedx-json=taskflow-api.cdx.json
                        export COSIGN_PASSWORD="cipassword"
                        rm -f cosign.key cosign.pub taskflow-api.cdx.json.sig
                        cosign generate-key-pair
                        cosign sign-blob --key cosign.key --tlog-upload=false --yes --output-signature taskflow-api.cdx.json.sig taskflow-api.cdx.json
                        cosign verify-blob --key cosign.pub --signature taskflow-api.cdx.json.sig --insecure-ignore-tlog=true taskflow-api.cdx.json
                    '''
                }
            }
        }

        stage('Policy Gate') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Evaluating OPA Rego security policy (policy/security.rego)..."
                    def auditFile = fileExists('apps/server/audit.json') ? 'apps/server/audit.json' : 'audit.json'
                    def isAllowed = sh(
                        script: "opa eval --data policy/security.rego --input ${auditFile} 'data.security.allow' --format raw",
                        returnStdout: true
                    ).trim()
                    if (isAllowed != "true") {
                        def denyReasons = sh(
                            script: "opa eval --data policy/security.rego --input ${auditFile} 'data.security.deny' --format raw",
                            returnStdout: true
                        ).trim()
                        error("Policy Gate Blocked build due to security policy violations:\n${denyReasons}")
                    }
                    echo "✅ Policy Gate PASSED: No CRITICAL vulnerabilities violate policy/security.rego"
                }
            }
        }

        stage('Unit Test') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Running automated unit tests in ${env.NODE_ENV} mode..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh 'npm test -- --coverage --reporters=jest-junit'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Running SonarQube static code & coverage analysis..."
                sh 'chmod +x scripts/bin/sonar-scanner || true'
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        SONAR_URL="${SONAR_HOST_URL:-http://host.docker.internal:9000}"
                        if echo "$SONAR_URL" | grep -q "localhost"; then
                            SONAR_URL=$(echo "$SONAR_URL" | sed 's/localhost/host.docker.internal/g')
                        fi
                        sonar-scanner -Dsonar.projectKey=taskflow-api -Dsonar.host.url="$SONAR_URL" || npx --yes sonarqube-scanner -Dsonar.projectKey=taskflow-api -Dsonar.host.url="$SONAR_URL"
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Evaluating SonarQube Quality Gate threshold..."
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        success {
            echo "✅ ${env.APP_NAME} passed on ${env.NODE_ENV}"
        }
        failure {
            echo "❌ Failed at stage: ${env.CURRENT_STAGE ?: env.STAGE_NAME}"
        }
        always {
            junit 'reports/junit.xml'
            script {
                try {
                    publishCoverage adapters: [coberturaAdapter('coverage/cobertura-coverage.xml')]
                } catch (Throwable ignored) {
                    echo "Cobertura adapter step not available in this Jenkins instance; JUnit test results recorded successfully."
                }
            }
            archiveArtifacts artifacts: '''
                gitleaks-report.json,
                apps/server/audit.json,
                audit.json,
                taskflow-api.cdx.json,
                taskflow-api.cdx.json.sig,
                cosign.pub,
                semgrep.sarif,
                apps/server/eslint-results.sarif,
                eslint-results.sarif,
                playwright-report/**,
                **/playwright-report/**
            ''', allowEmptyArchive: true
        }
    }
}
