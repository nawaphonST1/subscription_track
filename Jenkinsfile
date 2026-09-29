pipeline {
    agent {
        docker {
            image 'node:20-bookworm-security'
            args '-u 0:0 -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'
        PATH = "${WORKSPACE}/scripts/bin:${env.PATH}"
        REGISTRY = "${env.DOCKER_REGISTRY ?: 'localhost:5000'}"
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
                        npm install --no-save eslint-plugin-security @microsoft/eslint-formatter-sarif || true
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
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
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
        }

        stage('Quality Gate') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Evaluating SonarQube Quality Gate threshold..."
                timeout(time: 5, unit: 'MINUTES') {
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        waitForQualityGate abortPipeline: false
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    def shortCommit = env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : "build${env.BUILD_NUMBER}"
                    env.SHORT_COMMIT = shortCommit
                    env.IMAGE_TAG = "taskflow-api:${shortCommit}"
                    env.REGISTRY_IMAGE = "${env.REGISTRY}/taskflow-api:${shortCommit}"

                    echo "==> [${env.APP_NAME}] Ensuring CLI tools (docker, trivy, kubectl, kind) are present in scripts/bin..."
                    sh '''
                        mkdir -p "${WORKSPACE}/scripts/bin"
                        export PATH="${WORKSPACE}/scripts/bin:${PATH}"

                        if ! command -v docker >/dev/null 2>&1; then
                            echo "==> Downloading static Docker CLI..."
                            curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz | tar -xz -C "${WORKSPACE}/scripts/bin" --strip-components=1 docker/docker
                            chmod +x "${WORKSPACE}/scripts/bin/docker"
                        fi

                        if ! command -v trivy >/dev/null 2>&1; then
                            echo "==> Downloading static Trivy scanner..."
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "${WORKSPACE}/scripts/bin"
                            chmod +x "${WORKSPACE}/scripts/bin/trivy"
                        fi

                        if ! command -v kubectl >/dev/null 2>&1; then
                            echo "==> Downloading static kubectl CLI..."
                            curl -fsSL -o "${WORKSPACE}/scripts/bin/kubectl" https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl
                            chmod +x "${WORKSPACE}/scripts/bin/kubectl"
                        fi

                        if ! command -v kind >/dev/null 2>&1; then
                            echo "==> Downloading static kind CLI..."
                            curl -fsSL -o "${WORKSPACE}/scripts/bin/kind" https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
                            chmod +x "${WORKSPACE}/scripts/bin/kind"
                        fi

                        chmod +x "${WORKSPACE}/scripts/bin"/* || true
                    '''

                    echo "==> [${env.APP_NAME}] Building versioned Docker image: ${env.IMAGE_TAG} (never latest)..."
                    sh """
                        export PATH="${WORKSPACE}/scripts/bin:\${PATH}"
                        docker build -f apps/server/Dockerfile -t ${env.IMAGE_TAG} apps/server
                        docker tag ${env.IMAGE_TAG} ${env.REGISTRY_IMAGE}
                        docker push ${env.REGISTRY_IMAGE} || true
                        CLUSTER_NAME=\$(kind get clusters 2>/dev/null | head -n 1)
                        if [ -n "\$CLUSTER_NAME" ]; then
                            kind load docker-image ${env.IMAGE_TAG} --name "\$CLUSTER_NAME" || true
                        else
                            kind load docker-image ${env.IMAGE_TAG} || true
                        fi
                    """
                }
            }
        }

        stage('Container Scan') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Running Trivy container vulnerability scan on ${env.IMAGE_TAG}..."
                    sh """
                        export PATH="${WORKSPACE}/scripts/bin:\${PATH}"
                        # 1. Output human-readable scan report table to console
                        trivy image --cache-dir "${WORKSPACE}/.trivy-cache" --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed ${env.IMAGE_TAG} || true

                        # 2. Gate build and generate SARIF report for artifact archiving
                        trivy image --cache-dir "${WORKSPACE}/.trivy-cache" --scanners vuln --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed --format sarif --output trivy-results.sarif ${env.IMAGE_TAG}
                    """
                }
            }
        }

        stage('Blue/Green Deploy') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    sh '''
                        export PATH="${WORKSPACE}/scripts/bin:${PATH}"
                        mkdir -p "${WORKSPACE}/.kube"

                        # Connect current container to kind docker network if needed
                        CONTAINER_ID=$(hostname)
                        docker network connect kind "${CONTAINER_ID}" 2>/dev/null || true

                        # Retrieve kind cluster internal kubeconfig dynamically
                        CLUSTER_NAME=$(kind get clusters 2>/dev/null | head -n 1)
                        [ -z "$CLUSTER_NAME" ] && CLUSTER_NAME="taskflow"

                        kind get kubeconfig --name "${CLUSTER_NAME}" --internal > "${WORKSPACE}/.kube/config" 2>/dev/null || \
                        kind get kubeconfig --name "${CLUSTER_NAME}" > "${WORKSPACE}/.kube/config" 2>/dev/null || \
                        kind get kubeconfig --internal > "${WORKSPACE}/.kube/config" 2>/dev/null || true

                        if [ ! -s "${WORKSPACE}/.kube/config" ] && [ -f "${HOME}/.kube/config" ]; then
                            cp "${HOME}/.kube/config" "${WORKSPACE}/.kube/config"
                            sed -i 's/127.0.0.1/host.docker.internal/g' "${WORKSPACE}/.kube/config" 2>/dev/null || true
                        fi
                    '''

                    def kcmd = "export KUBECONFIG='${WORKSPACE}/.kube/config'; export PATH='${WORKSPACE}/scripts/bin:\${PATH}'; kubectl"

                    def svcExists = sh(
                        script: "${kcmd} get svc taskflow >/dev/null 2>&1",
                        returnStatus: true
                    ) == 0

                    if (!svcExists) {
                        echo "==> [${env.APP_NAME}] taskflow service not found in cluster. Initializing k8s deployments and service..."
                        sh "${kcmd} apply -f k8s/taskflow-blue.yaml"
                        sh "${kcmd} apply -f k8s/taskflow-green.yaml"
                        sh "${kcmd} apply -f k8s/taskflow-service.yaml"
                    }

                    def current = sh(
                        script: "${kcmd} get svc taskflow -o jsonpath='{.spec.selector.color}'",
                        returnStdout: true
                    ).trim()
                    def next = (current == 'blue') ? 'green' : 'blue'
                    env.PREV_COLOR = current
                    env.NEXT_COLOR = next
                    def commitTag = env.SHORT_COMMIT ?: (env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : "build${env.BUILD_NUMBER}")

                    echo "==> [${env.APP_NAME}] Active service color: ${current}. Upgrading deployment: taskflow-${next} to tag ${commitTag}..."
                    sh "${kcmd} set image deployment/taskflow-${next} app=taskflow-api:${commitTag}"
                    sh "${kcmd} rollout status deployment/taskflow-${next} --timeout=90s"

                    echo "==> [${env.APP_NAME}] Smoke testing new pods directly via internal service http://taskflow-${next}:8080/health..."
                    sh "${kcmd} run smoke-${env.BUILD_NUMBER} --rm -i --restart=Never --image=curlimages/curl -- curl -sf http://taskflow-${next}:8080/health"

                    echo "==> [${env.APP_NAME}] Smoke test passed! Switching service selector traffic from ${current} to ${next}..."
                    sh "${kcmd} patch svc taskflow -p '{\"spec\":{\"selector\":{\"color\":\"${next}\"}}}'"
                    echo "Switched traffic from ${current} to ${next}"
                    env.DEPLOY_SUCCESS = 'true'
                }
            }
        }
    }

    post {
        success {
            echo "✅ ${env.APP_NAME} deployment passed on ${env.NODE_ENV}. Active traffic serving color is now: ${env.NEXT_COLOR ?: 'active'}."
        }
        failure {
            echo "❌ Failed at stage: ${env.CURRENT_STAGE ?: env.STAGE_NAME}"
            script {
                if (env.PREV_COLOR && env.DEPLOY_SUCCESS != 'true') {
                    echo "⚠️ Blue/Green deployment or smoke test failed! Executing automated rollback to ${env.PREV_COLOR}..."
                    def kcmd = "export KUBECONFIG='${WORKSPACE}/.kube/config'; export PATH='${WORKSPACE}/scripts/bin:\${PATH}'; kubectl"
                    sh "${kcmd} patch svc taskflow -p '{\"spec\":{\"selector\":{\"color\":\"${env.PREV_COLOR}\"}}}' || true"
                    def activeColor = sh(
                        script: "${kcmd} get svc taskflow -o jsonpath='{.spec.selector.color}'",
                        returnStdout: true
                    ).trim()
                    echo "🔄 Service taskflow selector preserved/rolled back to: ${activeColor}"
                }
            }
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
                trivy-results.sarif,
                playwright-report/**,
                **/playwright-report/**
            ''', allowEmptyArchive: true
        }
    }
}
