pipeline {
    agent {
        docker {
            image 'node:20-alpine'
        }
    }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'
    }

    options {
        // [TIMEOUT JUSTIFICATION]:
        // A pipeline stage or build should never run unbounded to prevent hung, deadlocked,
        // or stalled processes (e.g. frozen network socket during dependency installation,
        // deadlocked database connection, or hung test runners) from monopolizing Jenkins
        // executor slots indefinitely. Without a bounded timeout, stuck jobs exhaust build
        // farm capacity, starve subsequent queued builds across the engineering organization,
        // and drive up unnecessary cloud or server infrastructure costs.
        timeout(time: 10, unit: 'MINUTES')
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
                    sh 'npm test'
                }
            }
        }

        stage('Deploy — Staging') {
            when {
                branch 'develop'
            }
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                sh 'echo deploying to staging--.'
            }
        }

        stage('Deploy — Production') {
            when {
                beforeInput true
                branch 'main'
            }
            input {
                message 'Deploy to production?'
            }
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                sh 'echo deploying to production--.'
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
            archiveArtifacts artifacts: 'npm-debug.log*', allowEmptyArchive: true
        }
    }
}
