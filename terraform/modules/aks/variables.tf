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

variable "kubernetes_version" {
  type    = string
  default = "1.28"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "subnet_id" {
  type = string
}

variable "container_registry_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
