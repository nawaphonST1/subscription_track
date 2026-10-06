# ==============================================================================
# Outputs สำหรับ DP-200 (Cloud Network) & DP-201 (Compute / Kubernetes)
# ==============================================================================

# --- DP-200: Cloud Network Outputs ---
output "public_ip_address" {
  description = "Static Public IP address of the Production Web Server"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "resource_group_name" {
  description = "Name of the created Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

# --- DP-201: Compute VM (Self-managed Node) Outputs ---
output "ssh_command" {
  description = "Command to SSH into the Production VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
}

# --- DP-201: Managed Kubernetes (AKS) Option Outputs ---
output "aks_cluster_name" {
  description = "Name of the AKS Cluster (กรณีเปิดใช้งาน enable_aks_cluster)"
  value       = var.enable_aks_cluster ? azurerm_kubernetes_cluster.aks[0].name : "AKS disabled (running on single VM)"
}

output "aks_kube_config_command" {
  description = "คำสั่งดึง kubeconfig ของ AKS เข้าเครื่อง local เพื่อใช้ kubectl"
  value       = var.enable_aks_cluster ? "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks[0].name}" : "AKS disabled"
}
