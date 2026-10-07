# ==============================================================================
# terraform.tfvars
# Configuration values for Azure Infrastructure & AKS Cluster (Plan 1)
# ==============================================================================

# --- Azure General Configuration ---
resource_group_name = "rg-subtracker-prod"
location            = "southeastasia" # สิงคโปร์
environment         = "production"

# --- DP-200: Network Configuration ---
vnet_address_space    = ["10.0.0.0/16"]
subnet_address_prefix = ["10.0.1.0/24"]

# --- DP-201: Production Compute VM (Primary Setup) ---
vm_size        = "Standard_B2s" # 2 vCPU, 4 GiB RAM
os_disk_size_gb = 64
admin_username = "azureuser"
admin_password = "SubTrackerProd2026!#"
ssh_public_key = ""

# --- DP-201: Managed Kubernetes Cluster (Azure Kubernetes Service - AKS) ---
# เปิดใช้งาน AKS Cluster ตามแผนที่ 1 (Plan 1: Terraform Managed Kubernetes)
enable_aks_cluster = true
aks_node_count     = 1
aks_vm_size        = "Standard_B2s"
