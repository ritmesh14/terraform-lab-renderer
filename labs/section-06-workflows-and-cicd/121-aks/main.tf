# Lab 121 — Azure Kubernetes Service (AKS).
# A managed Kubernetes cluster with a system node pool (1 node). Key bits:
#  - identity { type = "SystemAssigned" }: AKS manages its own resources via MI.
#  - default_node_pool: the initial node group (VM size, count, disk).
#  - linux_profile + ssh_key: admin access to nodes.
#  - network_profile: Azure CNI, a service CIDR, a DNS service IP.
# After apply: az aks get-credentials -g rg-aks -n aks-cluster, then kubectl get nodes.
# Your SSH public key (e.g. contents of ~/.ssh/id_rsa.pub) for node admin login.
# Copy terraform.tfvars.example to terraform.tfvars and fill it in — tfvars files
# are NOT committed, and `sensitive = true` keeps the value out of plan/log output.
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
# Container for the cluster's control-plane resources. (Node VMs themselves land
# in a separate, auto-created managed resource group starting with MC_.)
resource "azurerm_resource_group" "this" {
  name     = "rg-aks"
  location = "eastus"
}

# A managed Kubernetes cluster: Azure runs the control plane (API server,
# etcd, scheduler) for you; you size and pay for the node pool (worker VMs).
resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "aks-cluster"
  # A supported Kubernetes minor version — AKS refuses to create unsupported ones.
  kubernetes_version = "1.27"

  # The initial group of worker nodes (the VMs your pods run on). One small
  # node keeps the lab cheap; `only_critical_addons` restricts this pool to
  # system pods (add a separate user pool for real workloads).
  default_node_pool {
    name                         = "systempool"
    node_count                   = 1
    vm_size                      = "Standard_B2s"
    os_disk_size_gb              = 30
    only_critical_addons_enabled = true
  }

  # A managed identity Azure creates for the cluster, which AKS uses to manage
  # its own resources (load balancers, disks) — no service-principal secrets.
  identity {
    type = "SystemAssigned"
  }

  # SSH access to the Linux nodes (debugging only — you rarely need it).
  linux_profile {
    admin_username = "azureadmin"
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  # Networking: Azure CNI gives every pod a real VNet IP. service_cidr is a
  # virtual range for ClusterIP services, and dns_service_ip must sit inside it.
  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.43.0.0/16"
    dns_service_ip = "10.43.0.10"
  }
}

# Handy values: the name for `az aks get-credentials -n`, and the full Azure
# resource id if another stack or pipeline needs to reference the cluster.
output "cluster_name" { value = azurerm_kubernetes_cluster.this.name }
output "cluster_id" { value = azurerm_kubernetes_cluster.this.id }
