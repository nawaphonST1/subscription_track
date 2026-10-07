# ==============================================================================
# DP-201: Terraform Managed Kubernetes Cluster (Azure Kubernetes Service - AKS)
# ==============================================================================
# ไฟล์นี้จัดทำขึ้นเป็น Option เสริมสำหรับ Issue #46 (DP-201):
# "Terraform scripts for managed Kubernetes Cluster (EKS / GKE / Self-managed k8s)"
#
# โดยตั้งค่าสวิตช์ toggle var.enable_aks_cluster = false ไว้เป็นค่าเริ่มต้น
# - หาก enable_aks_cluster = false (ค่าเริ่มต้น):
#     จะไม่สร้าง AKS เพื่อประหยัดค่าใช้จ่าย Azure Credit ของนักศึกษา
#     และใช้งาน Single VM + Docker / K3s (Self-managed K8s) ตามแผนของทีม
# - หาก enable_aks_cluster = true:
#     Terraform จะสร้าง Azure Managed Kubernetes Cluster (AKS) ให้อัตโนมัติ
# ==============================================================================

resource "azurerm_kubernetes_cluster" "aks" {
  count               = var.enable_aks_cluster ? 1 : 0
  name                = "aks-subtracker-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "subtracker-k8s"
  kubernetes_version  = var.kubernetes_version

  # Node Pool สำหรับรัน Pods และ Workloads
  default_node_pool {
    name       = "defaultpool"
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
    os_disk_size_gb = 64
    os_disk_type    = "Managed"

    # รองรับ Auto-scaling ประหยัดงบ (เริ่มต้น 1 โหนด ขยายได้สูงสุด 3 โหนด)
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3

    tags = azurerm_resource_group.rg.tags
  }

  # ใช้ Managed Identity แทน Service Principal แบบเก่า (ตามมาตรฐานความปลอดภัย Azure)
  identity {
    type = "SystemAssigned"
  }

  # เครือข่ายของ Cluster
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  tags = azurerm_resource_group.rg.tags
}
