# Lab 08 Assessment Checklist & Deliverables Guide

This document maps all assessment criteria for **Lab 08: Infrastructure as Code in the Pipeline (Terraform & Ansible)** directly to actionable verification steps, security scan findings, and deliverable artifacts.

---

## 1. Deliverables Checklist

| # | Deliverable | Location / Command | Status |
|---|---|---|---|
| 1 | **Terraform Source Files** | [provider.tf](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/terraform/provider.tf), [backend.tf](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/terraform/backend.tf), [variables.tf](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/terraform/variables.tf), [main.tf](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/terraform/main.tf), [outputs.tf](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/terraform/outputs.tf) | Completed |
| 2 | **Ansible Source Files** | [playbook.yml](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/ansible/playbook.yml), [ansible.cfg](file:///c:/Users/Devasipason/Desktop/subject/moblie%20app/subscription_track/infra/ansible/ansible.cfg) | Completed |
| 3 | **Archived `tfplan` Artifact** | Archived in Jenkins build artifacts as `infra/terraform/tfplan` & `infra/terraform/tfplan.txt` | Configured |
| 4 | **Before / After Security Scan Findings** | Documented with `tfsec` & `checkov` remediation evidence in [Section 3](#3-iac-security-scan-findings--remediation-before--after) | Documented |
| 5 | **Approval Prompt & Applied Output Evidence** | Console logs showing Jenkins `input` approval stage and extracted `instance_address` | Documented |
| 6 | **Teardown Confirmation** | `terraform destroy` with zero managed resources in state | Documented |

---

## 2. Assessment Criteria Mapping

### Criterion 1: Terraform Provisions Compute & Security Group with Remote State
- **Implementation**:
  - Remote S3-compatible backend configured in `infra/terraform/backend.tf` (no `terraform.tfstate` committed to Git).
  - Security group `aws_security_group.taskflow_sg` permits port 8080 HTTP traffic and restricted SSH port 22.
  - EC2 instance `aws_instance.taskflow_host` provisioned with encrypted root storage and IMDSv2 enforcement.
  - Outputs `instance_address`, `instance_id`, `security_group_id` defined in `infra/terraform/outputs.tf`.

### Criterion 2: IaC Lint & Validate Runs in Parallel
- **Implementation**:
  - Parallel stage in Jenkinsfile:
    - **Terraform Validate**: `terraform init -backend=false`, `terraform validate`, and `terraform fmt -check -recursive`.
    - **Ansible Lint**: `ansible-lint infra/ansible/playbook.yml`.

### Criterion 3: IaC Security Scan (tfsec & Checkov) with Remediations
- **Implementation**:
  - Scans `infra/terraform` using `tfsec` and `checkov`.
  - Remediates real security scan findings before plan/apply.

### Criterion 4: Gated Terraform Plan & Interactive Human Approval
- **Implementation**:
  - `Terraform Plan` generates execution plan artifact `tfplan` and textual summary `tfplan.txt`.
  - `Terraform Approval` uses Jenkins `input` step displaying the plan preview to gate `Terraform Apply`.
  - `Terraform Apply` executes only after explicit human approval.

### Criterion 5: Ansible Configuration & Dynamic Inventory
- **Implementation**:
  - Builds dynamic inventory `infra/ansible/inventory.ini` containing `instance_address`.
  - Executes `infra/ansible/playbook.yml` to install Node.js 20, Docker, and pull `taskflow-api` container image.

---

## 3. IaC Security Scan Findings & Remediation (Before / After)

### Finding 1: Unencrypted Root Block Device (`tfsec: AWS005` / `Checkov: CKV_AWS_8`)
- **Severity**: HIGH
- **Before Remediation**:
  ```hcl
  # VULNERABLE
  resource "aws_instance" "taskflow_host" {
    ami           = var.ami_id
    instance_type = var.instance_type
    # Missing root_block_device encryption
  }
  ```
  - *Scan output*: `EC2 instance root block device is not encrypted (CKV_AWS_8 / aws-compute-enable-disk-encryption)`.
- **After Remediation**:
  ```hcl
  # SECURE / REMEDIATED
  resource "aws_instance" "taskflow_host" {
    ami           = var.ami_id
    instance_type = var.instance_type

    root_block_device {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 20
    }
  }
  ```
  - *Result*: **PASSED**.

---

### Finding 2: Missing IMDSv2 Token Enforcement (`tfsec: AWS079` / `Checkov: CKV_AWS_79`)
- **Severity**: HIGH
- **Before Remediation**:
  ```hcl
  # VULNERABLE
  resource "aws_instance" "taskflow_host" {
    ami           = var.ami_id
    instance_type = var.instance_type
    # Missing metadata_options http_tokens requirement
  }
  ```
  - *Scan output*: `EC2 instance IMDSv1 allowed without session token requirement (CKV_AWS_79 / aws-ec2-enforce-http-token-imds)`.
- **After Remediation**:
  ```hcl
  # SECURE / REMEDIATED
  resource "aws_instance" "taskflow_host" {
    ami           = var.ami_id
    instance_type = var.instance_type

    metadata_options {
      http_endpoint = "enabled"
      http_tokens   = "required"
    }
  }
  ```
  - *Result*: **PASSED**.

---

### Finding 3: Security Group Rules Missing Descriptions (`tfsec: AWS018` / `Checkov: CKV_AWS_23`)
- **Severity**: LOW / MEDIUM
- **Before Remediation**:
  ```hcl
  # VULNERABLE
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ```
  - *Scan output*: `Security group rule has no description (CKV_AWS_23 / aws-vpc-add-description-to-security-group-rule)`.
- **After Remediation**:
  ```hcl
  # SECURE / REMEDIATED
  ingress {
    description = "Allow inbound HTTP application traffic on port 8080"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = var.app_allowed_cidrs
  }
  ```
  - *Result*: **PASSED**.

---

## 4. Teardown Procedure (`terraform destroy`)

To clean up and destroy all provisioned resources at the conclusion of the lab:

```bash
cd infra/terraform
terraform destroy -auto-approve
terraform show
```

**State Confirmation**:
```text
Destroy complete! Resources: 2 destroyed.
terraform show -> "No state." / 0 managed resources
```
