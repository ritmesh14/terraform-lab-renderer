# variables.tf — inputs.
# Input variable: the VM's name, overridable with -var / tfvars.
variable "vm_name" {
  type    = string
  default = "vm-structured"
}
