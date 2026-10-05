# Cloud Infrastructure as Code (Terraform)

โฟลเดอร์นี้ประกอบด้วยชุดสคริปต์ **Terraform (HCL)** สำหรับสร้างและบริหารจัดการโครงสร้างพื้นฐานบน **Microsoft Azure** โดยรองรับงานสองหัวข้อหลัก:
1. **DP-200 (Issue #45):** Cloud Network Provisioning (VNet, Subnets, Network Security Groups, Static Public IP)
2. **DP-201 (Issue #46):** Compute VM & Managed Kubernetes Provisioning (Azure Linux VM, Docker/K3s Cloud-init, Optional AKS)

---

## 🏗️ โครงสร้างไฟล์ (File Structure)

| ไฟล์ | หน้าที่หลัก | Issue ที่เกี่ยวข้อง |
|---|---|---|
| `main.tf` | กำหนด Azure Provider, Resource Group, Virtual Network (VNet), Subnet, Static Public IP, และ Network Interface (NIC) | **DP-200** |
| `security.tf` | กำหนด Network Security Group (NSG) กฎไฟร์วอลล์ (พอร์ต 80, 443, 22) และการผูกเข้ากับ NIC | **DP-200** |
| `compute.tf` | กำหนด Azure Linux VM (Ubuntu 24.04 LTS, Standard_B2s, 64 GB Disk) พร้อมสคริปต์ Cloud-init ติดตั้ง Docker / K3s | **DP-201** (Self-managed Host) |
| `aks.tf` | สคริปต์สร้าง Azure Kubernetes Service (AKS) Managed Cluster พร้อม Auto-scaling (1-3 nodes) **[Option เสริม]** | **DP-201** (Managed K8s) |
| `variables.tf` | ประกาศตัวแปรทั้งหมด พร้อมค่า Default ที่ปรับจูนให้ประหยัดงบ Azure Credit ของนักศึกษา | ทั้งหมด |
| `outputs.tf` | ส่งออกค่าผลลัพธ์ เช่น Static Public IP, คำสั่ง SSH, ชื่อทรัพยากร | ทั้งหมด |
| `terraform.tfvars.example` | ไฟล์ตัวอย่างการตั้งค่าตัวแปร (สำหรับคัดลอกไปเป็น `terraform.tfvars`) | ทั้งหมด |

---

## ⚙️ ข้อกำหนดและสเปกทรัพยากร (Resource Specifications)

- **Cloud Provider:** Microsoft Azure
- **Region:** `southeastasia` (สิงคโปร์ - Latency ต่ำที่สุดสำหรับประเทศไทย)
- **Virtual Network (VNet):** `10.0.0.0/16`
- **Production Subnet:** `10.0.1.0/24`
- **Network Security Group (NSG):**
  - พอร์ต `80` (HTTP) — Inbound สำหรับ Certbot / Traefik Redirect
  - พอร์ต `443` (HTTPS) — Inbound สำหรับ Production Web & Mobile API
  - พอร์ต `22` (SSH) — Inbound สำหรับดูแลระบบ และต่อท่อ SSH Tunnel จาก Monitoring Server
- **Compute VM:**
  - Size: `Standard_B2s` (2 vCPU, 4 GiB RAM)
  - OS Disk: `64 GB` Standard_LRS
  - OS Image: Ubuntu 24.04 LTS
  - Automation: ติดตั้ง Docker และ Docker Compose อัตโนมัติผ่าน Cloud-init
- **Managed Kubernetes (AKS Option):**
  - ค่าเริ่มต้น `enable_aks_cluster = false` เพื่อไม่ให้เกิดค่าใช้จ่ายส่วนเกิน
  - สามารถเปิดใช้งานได้ผ่านการตั้งค่า `enable_aks_cluster = true`

---

## 🚀 ขั้นตอนการใช้งาน (Quick Start Guide)

### 1. ติดตั้งและเข้าสู่ระบบ Azure CLI
```bash
# ตรวจสอบการล็อกอินบัญชี Azure
az login

# ตรวจสอบ Subscription ปัจจุบัน
az account show
```

### 2. เตรียมไฟล์ Configuration
```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# ปรับแต่งค่าตามต้องการในไฟล์ terraform.tfvars
```

### 3. เริ่มต้นและสั่งสร้างทรัพยากร
```bash
# ดาวน์โหลด Azure Provider plugins
terraform init

# ตรวจสอบแผนการสร้างทรัพยากร
terraform plan

# ยืนยันการสร้างโครงสร้างพื้นฐานบน Azure
terraform apply
```

### 4. ตรวจสอบผลลัพธ์
เมื่อสร้างเสร็จสิ้น Terraform จะแสดงผลลัพธ์:
- `public_ip_address`: หมายเลข IP สาธารณะแบบคงที่ (Static)
- `ssh_command`: คำสั่ง SSH เพื่อเข้าเครื่อง VM ทันที เช่น:
  ```bash
  ssh azureuser@<PUBLIC_IP>
  ```

---

## 🧹 การลบทรัพยากรเพื่อคืนโควตา (Teardown)
เมื่อเสร็จสิ้นการสาธิตหรือทดสอบ สามารถลบทรัพยากรทั้งหมดเพื่อไม่ให้เสียค่าใช้จ่ายต่อเนื่องได้ด้วยคำสั่ง:
```bash
terraform destroy
```
