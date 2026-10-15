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
<<<<<<< HEAD
resource "helm_release" "this" {
  depends_on = [
  null_resource.restore_db
]
  for_each = var.releases
 
  name             = each.key
  chart            = var.chart_path
  namespace        = "sharecare"
  create_namespace = true
  wait             = true
  timeout          = 600
  values           = [file(each.value.values_file)]
}
resource "azurerm_postgresql_flexible_server_database" "userdb" {
  name      = "userdb"
=======

locals {
  ns        = kubernetes_namespace_v1.sharecare.metadata[0].name
  sql_files = { users = "user.sql", post = "post.sql", media = "media.sql", charity = "charity.sql" }
}

# Four databases
resource "azurerm_postgresql_flexible_server_database" "db" {
  for_each  = local.sql_files
  name      = each.key
>>>>>>> 659421339faa99aaa39defbefd748aa21efc922d
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

<<<<<<< HEAD
resource "azurerm_postgresql_flexible_server_database" "charitydb" {
  name      = "charitydb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "mediadb" {
  name      = "mediadb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "postdb" {
  name      = "postdb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
resource "null_resource" "restore_db" {

  depends_on = [
    azurerm_postgresql_flexible_server_database.userdb,
    azurerm_postgresql_flexible_server_database.charitydb,
    azurerm_postgresql_flexible_server_database.mediadb,
    azurerm_postgresql_flexible_server_database.postdb
  ]

  provisioner "local-exec" {

    command = "powershell -ExecutionPolicy Bypass -File scripts/restore-db.ps1"

    environment = {
      DB_HOST     = azurerm_postgresql_flexible_server.postgres.fqdn
      DB_USER     = var.postgres_user
      DB_PASSWORD = var.postgres_password
    }
  }
}
=======
# Lab-only firewall rule so psql can load data from the machine running apply
resource "azurerm_postgresql_flexible_server_firewall_rule" "lab" {
  name             = "allow-lab"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# Load the SQL dumps (needs psql installed on the machine running apply)
resource "terraform_data" "load_data" {
  for_each   = local.sql_files
  depends_on = [azurerm_postgresql_flexible_server_database.db, azurerm_postgresql_flexible_server_firewall_rule.lab]

  provisioner "local-exec" {
    environment = { PGPASSWORD = var.postgres_password }
    command     = "psql \"host=${azurerm_postgresql_flexible_server.postgres.fqdn} port=5432 dbname=${each.key} user=${var.postgres_user} sslmode=require\" -f ${path.module}/../dbscripts/database/${each.value}"
  }
}

# Reuse the existing ACR (read-only)
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group
}

# Secrets the chart expects
resource "kubernetes_secret_v1" "db" {
  metadata {
    name      = "sharecare-db-credentials"
    namespace = local.ns
  }
  data = {
    DB_HOST     = azurerm_postgresql_flexible_server.postgres.fqdn
    DB_USER     = var.postgres_user
    DB_PASSWORD = var.postgres_password
  }
}

resource "kubernetes_secret_v1" "acr" {
  metadata {
    name      = "acr-pull-secret"
    namespace = local.ns
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (data.azurerm_container_registry.acr.login_server) = {
          username = data.azurerm_container_registry.acr.admin_username
          password = data.azurerm_container_registry.acr.admin_password
          auth     = base64encode("${data.azurerm_container_registry.acr.admin_username}:${data.azurerm_container_registry.acr.admin_password}")
        }
      }
    })
  }
}

# Ingress controller
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
}

# The four APIs, driven by his existing var.releases and var.chart_path
resource "helm_release" "api" {
  for_each  = var.releases
  name      = "${each.key}-api-helm"
  namespace = local.ns
  chart     = var.chart_path
  values    = [file("${path.module}/${each.value.values_file}")]
  set = [{
    name  = "database.name"
    value = each.value.database_name
  }]
  depends_on = [terraform_data.load_data, kubernetes_secret_v1.db, kubernetes_secret_v1.acr, helm_release.ingress_nginx]
}

# Web app (port 5000, public LoadBalancer)
resource "helm_release" "web" {
  name      = "web-helm"
  namespace = local.ns
  chart     = var.chart_path
  values = [yamlencode({
    fullnameOverride = "web-helm"
    image            = { repository = "${data.azurerm_container_registry.acr.login_server}/web", tag = "latest" }
    containerPort    = 5000
    service          = { type = "LoadBalancer", port = 80 }
    ingress          = { enabled = false }
    extraEnv         = [{ name = "BASE_URL", value = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/api" }]
  })]
  depends_on = [kubernetes_secret_v1.acr, kubernetes_secret_v1.db, helm_release.ingress_nginx]
}

# Gateway ingress: /api/<service> to the right API
resource "kubernetes_ingress_v1" "gateway" {
  metadata {
    name        = "sharecare-gateway"
    namespace   = local.ns
    annotations = { "nginx.ingress.kubernetes.io/rewrite-target" = "/$1" }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        dynamic "path" {
          for_each = {
            "/api/(users.*)"   = "user-api-helm"
            "/api/(posts.*)"   = "post-api-helm"
            "/api/(media.*)"   = "media-api-helm"
            "/api/(charity.*)" = "charity-api-helm"
          }
          content {
            path      = path.key
            path_type = "ImplementationSpecific"
            backend {
              service {
                name = path.value
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.ingress_nginx, helm_release.api]
}
>>>>>>> 659421339faa99aaa39defbefd748aa21efc922d
