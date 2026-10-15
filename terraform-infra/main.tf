resource "azurerm_resource_group" "rg" {

  name     = var.resource_group_name
  location = var.location

}
resource "azurerm_kubernetes_cluster" "aks" {

  name                = "sharecarechallenge-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dns_prefix = "sharecarechallenge"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "standard_b2ps_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "sharecarechallengepostgres"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = "eastus2"

  administrator_login    = var.postgres_user
  administrator_password = var.postgres_password

  version                = "18"

  sku_name               = "GP_Standard_D4ds_v5"

  storage_mb             = 32768

  zone                   = "1"
}
resource "azurerm_postgresql_flexible_server_database" "sharecare" {

  name      = "sharecare"
  server_id = azurerm_postgresql_flexible_server.postgres.id

  charset   = "UTF8"
  collation = "en_US.utf8"
}
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {

  name = "AllowAzure"

  server_id = azurerm_postgresql_flexible_server.postgres.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
resource "azurerm_storage_account" "storage" {

  name                     = "sharecarestorageprod"
  resource_group_name      = azurerm_resource_group.rg.name

  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "images" {

  name                  = "images"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
resource "kubernetes_namespace_v1" "sharecare" {
  metadata {
    name = "sharecare"
  }
}