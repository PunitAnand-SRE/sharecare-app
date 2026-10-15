variable "resource_group_name" {
  default = "rg-sharecareprod"
}

variable "location" {
  default = "eastus"
}

variable "postgres_user" {
  type = string
}

variable "postgres_password" {
  type      = string
  sensitive = true
}
variable "releases" {
  type = map(object({
    database_name = string
    values_file   = string
  }))
}
variable "chart_path" { type = string }

variable "acr_name" {
  type    = string
  default = "sharecareacr"
}
variable "acr_resource_group" {
  type    = string
  default = "sharecare-rg"
}
