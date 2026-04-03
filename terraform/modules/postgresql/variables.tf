variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "admin_username" {
  type      = string
  sensitive = true
}

variable "subnet_id" {
  type = string
}

variable "db_version" {
  type    = string
  default = "15"
}

variable "tags" {
  type = map(string)
}
