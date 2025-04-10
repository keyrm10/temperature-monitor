variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "temperature-monitor"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "main-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "internal"
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "public_ip_name" {
  description = "Public IP name"
  type        = string
  default     = "main-pip"
}

variable "public_ip_allocation" {
  description = "Public IP allocation method"
  type        = string
  default     = "Dynamic"
}

variable "nic_name" {
  description = "Network interface name"
  type        = string
  default     = "main-nic"
}

variable "nsg_name" {
  description = "Network security group name"
  type        = string
  default     = "main-nsg"
}

variable "nsg_rules" {
  description = "Network security group rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = [
    {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "Prometheus"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9090"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "Grafana"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3000"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

variable "vm_name" {
  description = "Virtual machine name"
  type        = string
  default     = "temperature-monitor"
}

variable "vm_size" {
  description = "Virtual machine size"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "os_disk_caching" {
  description = "OS disk caching type"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_type" {
  description = "OS disk storage type"
  type        = string
  default     = "Standard_LRS"
}
