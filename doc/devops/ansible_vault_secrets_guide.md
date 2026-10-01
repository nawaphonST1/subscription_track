# 🔐 Ansible Vault Secrets Management Guide

## 1. Overview & Objectives
To prevent secrets from leaking into Git repositories or pipeline build logs, all sensitive production configurations are stored in an encrypted Ansible Vault file (`infra/ansible/vars/vault.yml`) using **AES-256** encryption.

During automated deployments, Ansible decrypts the vault using a secure key injected at runtime, renders Kubernetes `Secret` manifests from [`infra/ansible/templates/k8s-secrets.yaml.j2`](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/ansible/templates/k8s-secrets.yaml.j2), and applies them directly to the target cluster.

---

## 2. Directory Structure

```
infra/ansible/
├── ansible.cfg                    # Configured with vault password location
├── vars/
│   ├── main.yml                   # Non-sensitive variables (ports, hostnames)
│   ├── vault.example.yml          # Schema template for required secrets
│   └── vault.yml                  # AES-256 ENCRYPTED vault file (Never commit unencrypted!)
└── templates/
    └── k8s-secrets.yaml.j2        # Jinja2 template rendering k8s secrets
```

---

## 3. Operator CLI Workflow

### Initializing a New Encrypted Vault
```bash
cp infra/ansible/vars/vault.example.yml infra/ansible/vars/vault.yml
ansible-vault encrypt infra/ansible/vars/vault.yml
```

### Viewing Encrypted Secrets
```bash
ansible-vault view infra/ansible/vars/vault.yml
```

### Editing Encrypted Secrets
```bash
ansible-vault edit infra/ansible/vars/vault.yml
```

### Rekeying (Rotating Vault Password)
```bash
ansible-vault rekey infra/ansible/vars/vault.yml
```

---

## 4. CI/CD Non-Interactive Pipeline Decryption

In automated pipelines (such as Jenkins), pass the vault password securely via environment credentials:

```groovy
withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASSWORD')]) {
    sh '''
        echo "${VAULT_PASSWORD}" > .vault_pass
        ansible-playbook -i inventory.ini playbook.yml --vault-password-file .vault_pass
        rm -f .vault_pass
    '''
}
```

---

## 5. Security Guardrails & Verification
1. `.vault_pass` is strictly ignored by `.gitignore`.
2. Gitleaks pre-commit hook automatically flags unencrypted vault files if plaintext high-entropy tokens are detected.
