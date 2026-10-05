# ==============================================================================
# DP-201: Compute VM Provisioning (Self-managed Production Host)
# ==============================================================================
# ทรัพยากรนี้สร้างเครื่อง Azure Linux VM สเปก 2 vCPU / 4 GiB RAM / OS Disk 64 GB
# ทำหน้าที่เป็น Web / API Production Server ตามแผนสถาปัตยกรรมประหยัดงบของทีม
# และรองรับทั้งการรัน Docker Compose และ Self-managed K8s (K3s)
# ==============================================================================

resource "azurerm_linux_virtual_machine" "prod_vm" {
  name                  = "vm-subtracker-prod"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = var.vm_size
  admin_username        = var.admin_username

  # ----------------------------------------------------------------------------
  # ระบบยืนยันตัวตน (Authentication)
  # - หากระบุ ssh_public_key จะปิด password authentication เพื่อความปลอดภัยสูงสุด (Security Lead Best Practice)
  # - หากไม่ได้ระบุ ssh_public_key จะใช้ admin_password ในการล็อกอิน
  # ----------------------------------------------------------------------------
  disable_password_authentication = var.ssh_public_key != "" ? true : false
  admin_password                  = var.ssh_public_key != "" ? null : var.admin_password

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  # OS Disk 64 GB (Standard_LRS ประหยัดงบสุด)
  os_disk {
    name                 = "osdisk-subtracker-prod"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  # Ubuntu 24.04 LTS (Noble Numbat)
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # ----------------------------------------------------------------------------
  # สคริปต์เริ่มต้นเครื่อง (Cloud-init): ติดตั้ง Docker & ตัวเลือก Self-managed K8s
  # ----------------------------------------------------------------------------
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              # Update packages
              apt-get update -y
              apt-get install -y curl ca-certificates gnupg lsb-release htop ufw

              # 1. ติดตั้ง Docker Engine + Docker Compose Plugin
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ${var.admin_username}

              # 2. ตัวเลือกสำหรับ Self-managed Kubernetes (K3s) สำหรับ DP-201:
              # หากต้องการรันระบบแบบ Lightweight Single-node Kubernetes ให้ uncomment ด้านล่าง:
              # curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
              EOF
  )

  tags = azurerm_resource_group.rg.tags
}
