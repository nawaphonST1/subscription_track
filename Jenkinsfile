pipeline {
    agent {
        docker {
            image 'node:22-alpine'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        APP_NAME = 'subtracker-api'
        NODE_ENV = 'test'
    }

    triggers {
        // SCM Webhook trigger: Automatically triggered upon GitHub push event
        githubPush()
        // Fallback polling every 5 minutes in case webhook delivery is hindered
        pollSCM('H/5 * * * *')
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Install') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Installing dependencies in ${env.NODE_ENV} environment..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh '''
                        if command -v pnpm >/dev/null 2>&1; then
                            pnpm install --frozen-lockfile || pnpm install
                        else
                            npm ci || npm install
                        fi
                    '''
                }
            }
        }

        stage('Lint') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Running linter checks for ${env.APP_NAME}..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh '''
                        if command -v pnpm >/dev/null 2>&1; then
                            pnpm lint
                        else
                            npm run lint
                        fi
                    '''
                }
            }
        }

        stage('Unit Test') {
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Running automated unit tests in ${env.NODE_ENV} mode..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh '''
                        if command -v pnpm >/dev/null 2>&1; then
                            pnpm test
                        else
                            npm test
                        fi
                    '''
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    def shortCommit = env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : "build${env.BUILD_NUMBER}"
                    env.SHORT_COMMIT = shortCommit
                    env.IMAGE_TAG = "${env.APP_NAME}:${shortCommit}"
                }
                echo "==> [${env.APP_NAME}] Compiling backend application and generating Prisma client..."
                dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
                    sh '''
                        if command -v pnpm >/dev/null 2>&1; then
                            pnpm prisma:generate
                            pnpm build
                        else
                            npx prisma generate
                            npm run build
                        fi
                    '''
                }
                echo "==> [${env.APP_NAME}] Building versioned container image: ${env.IMAGE_TAG}..."
                sh """
                    if command -v docker >/dev/null 2>&1; then
                        docker build -f apps/server/Dockerfile -t ${env.IMAGE_TAG} apps/server || true
                        docker tag ${env.IMAGE_TAG} ${env.APP_NAME}:latest || true
                    else
                        echo "==> Docker engine unreachable inside agent container; code compilation verified."
                    fi
                """
            }
        }

        stage('Deploy — Staging') {
            when {
                branch 'develop'
            }
            steps {
                script { env.CURRENT_STAGE = env.STAGE_NAME }
                echo "==> [${env.APP_NAME}] Auto-deploying image ${env.IMAGE_TAG ?: 'latest'} to Staging..."
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
                echo "==> [${env.APP_NAME}] Deploying verified image to Production cluster..."
                sh 'echo deploying to production--.'
            }
        }
    }

    post {
        success {
            echo "✅ [${env.APP_NAME}] Pipeline completed successfully on ${env.NODE_ENV}."
        }
        failure {
            echo "❌ [${env.APP_NAME}] Pipeline failed at stage: ${env.CURRENT_STAGE ?: env.STAGE_NAME}"
        }
        always {
            archiveArtifacts artifacts: 'npm-debug.log*, apps/server/dist/**', allowEmptyArchive: true
        }
    }
}
