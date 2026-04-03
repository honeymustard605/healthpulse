resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  # Enable OIDC for Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = var.tags
}

# Grant AKS identity access to container registry
resource "azurerm_role_assignment" "aks_acr" {
  scope              = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

resource "azurerm_kubernetes_cluster_node_pool" "worker" {
  name                  = "worker"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  node_count            = var.node_count
  vm_size               = var.vm_size
  vnet_subnet_id        = var.subnet_id

  node_labels = {
    "workload" = "app"
  }

  tags = var.tags
}
