pipeline {
    agent {
        docker {
            image 'node:20-alpine'
            label 'linux-build'
        }
    }
    environment {
        APP_NAME = 'subscription-track-api'
        NODE_ENV = 'test'
    }
    options {
        timeout(time: 10, unit: 'MINUTES')
        // A hung npm install or test run must not hold the executor forever; setting an explicit timeout prevents pipeline starvation and resource leaks
    }
    stages {
        stage('Install') {
            steps {
                echo "Running Install for ${env.APP_NAME} in environment ${env.NODE_ENV}"
                dir('apps/server') {
                    sh 'npm ci --legacy-peer-deps || npm install --legacy-peer-deps'
                }
            }
        }
        stage('Lint') {
            steps {
                echo "Running Lint for ${env.APP_NAME}"
                dir('apps/server') {
                    sh 'npm run lint'
                }
            }
        }
        stage('Unit Test') {
            steps {
                echo "Running Unit Test for ${env.APP_NAME}"
                dir('apps/server') {
                    sh 'npm test'
                }
            }
        }
    }
    post {
        success {
            echo " [PASS] ${env.APP_NAME} passed on ${env.NODE_ENV}"
        }
        failure {
            echo " [FAIL] Failed at stage: ${env.STAGE_NAME}"
        }
        always {
            archiveArtifacts artifacts: 'apps/server/npm-debug.log*', allowEmptyArchive: true
        }
    }
}
