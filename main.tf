# ===================================================
# Resource Group
# ===================================================
resource "azurerm_resource_group" "MalleshRes" {
  name     = "MalleshResEx"
  location = "West US 2"
}

# ===================================================
# Network Security Group (Shared across all VMs)
# ===================================================
resource "azurerm_network_security_group" "nsg" {
  name                = "MalleshNSG"
  location            = azurerm_resource_group.MalleshRes.location
  resource_group_name = azurerm_resource_group.MalleshRes.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ===================================================
# VM1 Setup (in VNet1, Subnet1, Public IP and Private IP)
# ===================================================

resource "azurerm_virtual_network" "vnet1" {
  name                = "MalleshVnet1"
  location            = azurerm_resource_group.MalleshRes.location
  resource_group_name = azurerm_resource_group.MalleshRes.name
  address_space       = ["10.5.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "MalleshSubnet1"
  resource_group_name  = azurerm_resource_group.MalleshRes.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "vm1_pip" {
  name                = "MalleshVM1PublicIP"
  location            = azurerm_resource_group.MalleshRes.location
  resource_group_name = azurerm_resource_group.MalleshRes.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic1" {
  name                = "MalleshNIC1"
  location            = azurerm_resource_group.MalleshRes.location
  resource_group_name = azurerm_resource_group.MalleshRes.name

  ip_configuration {
    name                          = "NICConfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm1" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "tls_private_key" "ssh_key1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private1" {
  content  = tls_private_key.ssh_key1.private_key_pem
  filename = "${path.module}/id_rsa_vm1"
}

resource "local_file" "ssh_pub1" {
  content  = tls_private_key.ssh_key1.public_key_openssh
  filename = "${path.module}/id_rsa_vm1.pub"
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "MalleshVM1"
  resource_group_name   = azurerm_resource_group.MalleshRes.name
  location              = azurerm_resource_group.MalleshRes.location
  size                  = "Standard_B1ls"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic1.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key1.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ===================================================
# VM2 Setup (in VNet1, Subnet2, only Private IP)
# ===================================================

resource "azurerm_subnet" "subnet2" {
  name                 = "MalleshSubnet2"
  resource_group_name  = azurerm_resource_group.MalleshRes.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.15.0.0/16"]
}

resource "azurerm_network_interface" "nic2" {
  name                = "MalleshNIC2"
  location            = azurerm_resource_group.MalleshRes.location
  resource_group_name = azurerm_resource_group.MalleshRes.name

  ip_configuration {
    name                          = "NICConfig2"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "tls_private_key" "ssh_key2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private2" {
  content  = tls_private_key.ssh_key2.private_key_pem
  filename = "${path.module}/id_rsa_vm2"
}

resource "local_file" "ssh_pub2" {
  content  = tls_private_key.ssh_key2.public_key_openssh
  filename = "${path.module}/id_rsa_vm2.pub"
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "MalleshVM2"
  resource_group_name   = azurerm_resource_group.MalleshRes.name
  location              = azurerm_resource_group.MalleshRes.location
  size                  = "Standard_B1ls"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic2.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key2.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "MalleshVnet2"
  address_space       = ["10.15.0.0/16"]
  location            = azurerm_resource_group.MalleshRes.location
  resource_group_name = azurerm_resource_group.MalleshRes.name
}

# ===================================================
# VNet Peering between VNet1 and VNet2
# ===================================================

resource "azurerm_virtual_network_peering" "peer1to2" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.MalleshRes.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "peer2to1" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.MalleshRes.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access = true
}

