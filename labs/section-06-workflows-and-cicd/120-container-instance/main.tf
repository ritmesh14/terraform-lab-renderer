# Lab 120 — Azure Container Instance (ACI).
# The fastest way to run a container in Azure — no orchestrator. One
# azurerm_container_group runs a public nginx image on port 80 with a public IP.
# Good for simple tasks/jobs; for production services use AKS (lab 121).
# Container for the resources below.
resource "azurerm_resource_group" "this" {
  name     = "rg-aci"
  location = "eastus"
}

# A container group is Azure's "pod": one or more containers sharing a host and
# an IP, billed per second, with no orchestrator to run or pay for. Changing
# `image` here forces a replace (containers are immutable) — the plan shows -/+.
resource "azurerm_container_group" "this" {
  name                = "aci-nginx"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  restart_policy      = "Always"

  # A nested block (repeated for each container in the group) — here just one.
  container {
    name   = "nginx"
    image  = "nginx:1.25-alpine"
    cpu    = "0.5"
    memory = "0.5"

    # Nested inside container: which ports the container listens on.
    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

# The public IP Azure assigned — open it in a browser (http://<ip>) to see nginx.
output "public_ip" { value = azurerm_container_group.this.ip_address }
