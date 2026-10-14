output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}