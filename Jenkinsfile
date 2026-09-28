pipeline {
    agent {
        docker {
            image 'node:20-alpine'
        }
    }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'
        PATH = "${WORKSPACE}/scripts/bin:${env.PATH}"
    }

    options {
        // [TIMEOUT JUSTIFICATION]:
        // A pipeline stage or build should never run unbounded to prevent hung, deadlocked,
        // or stalled processes (e.g. frozen network socket during dependency installation,
        // deadlocked database connection, or hung test runners) from monopolizing Jenkins
        // executor slots indefinitely. Without a bounded timeout, stuck jobs exhaust build
        // farm capacity, starve subsequent queued builds across the engineering organization,
        // and drive up unnecessary cloud or server infrastructure costs.
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

        stage('Lint') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Running linter checks for ${env.APP_NAME}..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh 'npm run lint'
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
                    sh 'sonar-scanner -Dsonar.projectKey=taskflow-api || npx --yes sonarqube-scanner -Dsonar.projectKey=taskflow-api'
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
            archiveArtifacts artifacts: 'npm-debug.log*', allowEmptyArchive: true
        }
    }
}
