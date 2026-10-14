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