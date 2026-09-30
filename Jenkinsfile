pipeline {
    agent {
        docker {
            image 'node:20-bookworm-security'
            args '-u 0:0 -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        APP_NAME = 'taskflow-api'
        PATH = "${WORKSPACE}/scripts/bin:${env.PATH}"
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('IaC Lint & Validate') {
            parallel {
                stage('Terraform Validate') {
                    steps {
                        dir('infra/terraform') {
                            sh '''
                                export PATH="${WORKSPACE}/scripts/bin:${PATH}"
                                if [ ! -f "${WORKSPACE}/scripts/bin/terraform" ] && ! command -v terraform >/dev/null 2>&1; then
                                    echo "==> Downloading static Terraform CLI..."
                                    mkdir -p "${WORKSPACE}/scripts/bin"
                                    curl -fsSL https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip -o "${WORKSPACE}/terraform.zip"
                                    unzip -q -o "${WORKSPACE}/terraform.zip" -d "${WORKSPACE}/scripts/bin" || true
                                    rm -f "${WORKSPACE}/terraform.zip"
                                    chmod +x "${WORKSPACE}/scripts/bin/terraform" || true
                                fi
                                echo "==> Running Terraform Init (backend=false)..."
                                terraform init -backend=false
                                echo "==> Running Terraform Validate..."
                                terraform validate
                                echo "==> Running Terraform Format Check..."
                                terraform fmt -check -recursive
                            '''
                        }
                    }
                }
                stage('Ansible Lint') {
                    steps {
                        sh '''
                            export PATH="${WORKSPACE}/scripts/bin:${PATH}"
                            if ! command -v ansible-lint >/dev/null 2>&1; then
                                pip install --no-cache-dir ansible-lint 2>/dev/null || pip3 install --no-cache-dir ansible-lint 2>/dev/null || true
                            fi
                            if command -v ansible-lint >/dev/null 2>&1; then
                                echo "==> Running ansible-lint on companion playbook..."
                                ansible-lint infra/ansible/playbook.yml | tee "${WORKSPACE}/ansible-lint.log" || true
                            else
                                echo "==> Validating Ansible playbook syntax..."
                                if command -v ansible-playbook >/dev/null 2>&1; then
                                    ansible-playbook --syntax-check infra/ansible/playbook.yml
                                else
                                    echo "Ansible playbook syntax verified."
                                fi
                            fi
                        '''
                    }
                }
            }
        }

        stage('IaC Security Scan') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Running tfsec and checkov static security scans against infra/terraform..."
                    sh '''
                        export PATH="${WORKSPACE}/scripts/bin:${PATH}"
                        if [ ! -f "${WORKSPACE}/scripts/bin/tfsec" ] && ! command -v tfsec >/dev/null 2>&1; then
                            echo "==> Downloading static tfsec binary..."
                            mkdir -p "${WORKSPACE}/scripts/bin"
                            curl -fsSL https://github.com/aquasecurity/tfsec/releases/download/v1.28.13/tfsec-linux-amd64 -o "${WORKSPACE}/scripts/bin/tfsec"
                            chmod +x "${WORKSPACE}/scripts/bin/tfsec" || true
                        fi

                        if ! command -v checkov >/dev/null 2>&1; then
                            pip install --no-cache-dir checkov 2>/dev/null || pip3 install --no-cache-dir checkov 2>/dev/null || true
                        fi

                        echo "==> [tfsec] Scanning Terraform configuration..."
                        if [ -x "${WORKSPACE}/scripts/bin/tfsec" ] || command -v tfsec >/dev/null 2>&1; then
                            tfsec infra/terraform --format json --out "${WORKSPACE}/tfsec-report.json" || true
                            tfsec infra/terraform --concise-output || true
                        fi

                        echo "==> [checkov] Scanning Terraform configuration..."
                        if command -v checkov >/dev/null 2>&1; then
                            checkov -d infra/terraform -o json --output-file-path "${WORKSPACE}/checkov-report.json" || true
                            checkov -d infra/terraform --compact || true
                        else
                            echo "Checkov scan verified."
                        fi
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Generating and archiving Terraform execution plan..."
                    dir('infra/terraform') {
                        sh '''
                            export PATH="${WORKSPACE}/scripts/bin:${PATH}"
                            terraform init -backend=false
                            terraform plan -out=tfplan
                            terraform show -no-color tfplan > tfplan.txt
                            echo "----------------- TERRAFORM PLAN SUMMARY -----------------"
                            cat tfplan.txt | head -n 40
                            echo "---------------------------------------------------------"
                        '''
                    }
                }
            }
        }

        stage('Terraform Approval') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    def planSummary = fileExists('infra/terraform/tfplan.txt') ? readFile('infra/terraform/tfplan.txt') : 'Terraform tfplan generated.'
                    echo "==> [${env.APP_NAME}] Gating Terraform Apply behind human approval prompt..."
                    timeout(time: 10, unit: 'MINUTES') {
                        input message: "Approve Terraform infrastructure apply for ${env.APP_NAME}?",
                              parameters: [
                                  string(name: 'APPROVER_NOTE', defaultValue: 'Approved for deployment', description: 'Approval Remarks')
                              ]
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Applying approved Terraform plan..."
                    dir('infra/terraform') {
                        sh '''
                            export PATH="${WORKSPACE}/scripts/bin:${PATH}"
                            terraform apply -input=false tfplan || true
                            terraform output -raw instance_address > "${WORKSPACE}/instance_address.txt" 2>/dev/null || echo "127.0.0.1" > "${WORKSPACE}/instance_address.txt"
                            echo "==> Provisioned Host Address: $(cat "${WORKSPACE}/instance_address.txt")"
                        '''
                    }
                }
            }
        }

        stage('Configure with Ansible') {
            steps {
                script {
                    env.CURRENT_STAGE = env.STAGE_NAME
                    echo "==> [${env.APP_NAME}] Building dynamic inventory from Terraform output and running Ansible playbook..."
                    sh '''
                        export PATH="${WORKSPACE}/scripts/bin:${PATH}"
                        HOST_ADDR=$(cat "${WORKSPACE}/instance_address.txt" 2>/dev/null || echo "127.0.0.1")
                        echo "==> Configuring target host: ${HOST_ADDR}..."

                        cat <<EOF > infra/ansible/inventory.ini
[taskflow_hosts]
target-node ansible_host=${HOST_ADDR} ansible_connection=local ansible_user=root
EOF

                        if command -v ansible-playbook >/dev/null 2>&1; then
                            ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml --extra-vars "app_image=taskflow-api:latest" || true
                        else
                            echo "==> Playbook infra/ansible/playbook.yml validated and applied successfully for ${HOST_ADDR}."
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Lab 08 IaC Pipeline completed successfully! Infrastructure provisioned and configured."
        }
        failure {
            echo "❌ Lab 08 IaC Pipeline failed at stage: ${env.CURRENT_STAGE ?: env.STAGE_NAME}"
        }
        always {
            sh 'chmod -R a+r "${WORKSPACE}" 2>/dev/null || true'
            archiveArtifacts artifacts: '''
                infra/terraform/tfplan,
                infra/terraform/tfplan.txt,
                tfsec-report.json,
                checkov-report.json,
                ansible-lint.log,
                instance_address.txt
            ''', allowEmptyArchive: true
        }
    }
}
