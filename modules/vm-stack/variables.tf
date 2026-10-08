# variables.tf — the module's INPUT contract. Every input here is a knob a caller can set.
# Validation (like the name_prefix regex) rejects bad inputs BEFORE plan.
variable "name_prefix" {
  type        = string
  description = "Lowercase alphanumeric prefix, 3-10 chars."

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.name_prefix))
    error_message = "name_prefix must be 3-10 lowercase alphanumerics."
  }
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "subnet_prefix" {
  type    = string
  default = "10.10.1.0/24"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "admin_ssh_key" {
  type      = string
  sensitive = true
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "custom_data" {
  type    = string
  default = ""
  description = "Base64-encoded cloud-init to run at first boot (optional)."
}

variable "tags" {
  type    = map(string)
  default = {}
}
