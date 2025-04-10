terraform {
  required_version = ">= 1.11.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.2.0"
    }
  }
}

data "sops_file" "azure_secrets" {
  source_file = "${path.module}/azure.enc.yaml"
}

locals {
  azure_secrets = yamldecode(data.sops_file.azure_secrets.raw)
}

provider "azurerm" {
  features {}
  subscription_id = local.azure_secrets.AZURE_SUBSCRIPTION_ID
  client_id       = local.azure_secrets.AZURE_CLIENT_ID
  client_secret   = local.azure_secrets.AZURE_CLIENT_SECRET
  tenant_id       = local.azure_secrets.AZURE_TENANT_ID
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_subnet" "internal" {
  name                 = var.subnet_name
  address_prefixes     = var.subnet_address_prefixes
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
}

resource "azurerm_public_ip" "main" {
  name                = var.public_ip_name
  allocation_method   = var.public_ip_allocation
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_network_interface" "main" {
  name                = var.nic_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_security_group" "main" {
  name                = var.nsg_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  user_data = filebase64("${path.module}/user_data.sh")
}
