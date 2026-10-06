variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
  default     = "rg-subtracker-prod"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
  default     = "southeastasia" # โซนสิงคโปร์ ใกล้ไทย ปิงต่ำที่สุด
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for Virtual Network"
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for Web Server Subnet"
  default     = ["10.0.1.0/24"]
}

variable "vm_size" {
  type        = string
  description = "Azure VM Size (2 vCPU / 4 GiB RAM)"
  default     = "Standard_B2s" # หรือ Standard_B2als_v2 ประหยัดงบสำหรับ Student
}

variable "os_disk_size_gb" {
  type        = number
  description = "OS Disk size in GB"
  default     = 64 # หรือ 50 GB ตามโควตา
}

variable "admin_username" {
  type        = string
  description = "Administrator username for the VM"
  default     = "azureuser"
}

variable "admin_password" {
  type        = string
  description = "Administrator password for the VM (ใช้กรณีไม่ได้ระบุ SSH Key)"
  default     = "SubTrackerProd2026!#"
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "SSH Public Key สำหรับล็อกอินเข้า VM (หากเว้นว่างไว้จะใช้รหัสผ่าน admin_password แทน)"
  default     = ""
}

# ==============================================================================
# ตัวเลือกเสริมสำหรับ DP-201: Managed Kubernetes Cluster (Azure Kubernetes Service - AKS)
# ปิดไว้เป็นค่าเริ่มต้น (false) เพื่อประหยัดงบ Azure Credit และเน้นรันบน Single VM ตามสเปกทีม
# หากต้องการสร้าง AKS จริง ให้ตั้งค่า enable_aks_cluster = true ใน terraform.tfvars
# ==============================================================================
variable "enable_aks_cluster" {
  type        = bool
  description = "เปิด/ปิด การสร้าง Azure Kubernetes Service (AKS) Managed Cluster สำหรับ DP-201 (Default: false)"
  default     = false
}

variable "aks_node_count" {
  type        = number
  description = "จำนวน Worker Node เริ่มต้นสำหรับ AKS Cluster"
  default     = 1
}

variable "aks_vm_size" {
  type        = string
  description = "ขนาด VM สำหรับ Worker Node ของ AKS Cluster"
  default     = "Standard_B2s"
}

