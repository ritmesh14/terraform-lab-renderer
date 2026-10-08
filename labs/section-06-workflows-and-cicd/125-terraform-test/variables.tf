# The storage account's performance tier, with a default so `terraform test`
# needs no inputs. Tests can override it to prove the config honors variables.
variable "tier" {
  type    = string
  default = "Standard"
}

