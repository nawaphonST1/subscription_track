terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "subscription-track"
    ManagedBy   = "Terraform"
  }
}

# 2. Virtual Network (VNet 10.0.0.0/16)
# เฉพาะ Standalone VM เท่านั้นที่ต้องใช้เครือข่ายนี้ — AKS (aks.tf) ใช้เครือข่าย kubenet
# ที่ Azure จัดการให้เองโดยอัตโนมัติ ไม่ได้อ้างอิงถึง VNet/Subnet ชุดนี้
resource "azurerm_virtual_network" "vnet" {
  count               = var.enable_standalone_vm ? 1 : 0
  name                = "vnet-subtracker"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = azurerm_resource_group.rg.tags
}

# 3. Production Subnet (10.0.1.0/24)
resource "azurerm_subnet" "subnet" {
  count                = var.enable_standalone_vm ? 1 : 0
  name                 = "snet-subtracker-prod"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = var.subnet_address_prefix
}

# 4. Static Public IP (สำหรับให้อินเทอร์เน็ต กรรมการ และ SSH เข้าได้ตลอดเวลา)
resource "azurerm_public_ip" "public_ip" {
  count               = var.enable_standalone_vm ? 1 : 0
  name                = "pip-subtracker-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.rg.tags
}

# 5. Network Interface (NIC) ผูก VM เข้ากับ Subnet และ Public IP
resource "azurerm_network_interface" "nic" {
  count               = var.enable_standalone_vm ? 1 : 0
  name                = "nic-subtracker-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[0].id
  }

  tags = azurerm_resource_group.rg.tags
}
