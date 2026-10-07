# Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  count               = var.enable_standalone_vm ? 1 : 0
  name                = "nsg-subtracker-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # กฎที่ 1: อนุญาต HTTP (Port 80) สำหรับต่ออายุ SSL และ Redirect ไป HTTPS
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # กฎที่ 2: อนุญาต HTTPS (Port 443) สำหรับทราฟฟิกเว็บและ API หลัก
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # กฎที่ 3: อนุญาต SSH (Port 22) สำหรับดูแลระบบและต่อท่อ SSH Tunnel จากเครื่องอาจารย์
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.rg.tags
}

# ผูก NSG เข้ากับ Network Interface ของเครื่อง VM
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  count                     = var.enable_standalone_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.nic[0].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}
