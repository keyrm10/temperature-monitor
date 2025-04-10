output "vm_public_ip" {
  description = "Public IP address of the virtual machine"
  value       = azurerm_public_ip.main.ip_address
}

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${azurerm_public_ip.main.ip_address}:3000"
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${azurerm_public_ip.main.ip_address}:9090"
}
