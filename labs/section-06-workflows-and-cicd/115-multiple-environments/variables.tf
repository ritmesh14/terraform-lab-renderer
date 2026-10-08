# Variable declarations moved to main.tf (they were declared twice, which Terraform rejects).
# Terraform merges all .tf files in a folder into one configuration, so a
# variable may only be declared ONCE across all of them. The actual variable
# blocks (environment, location, tags) live at the top of main.tf; the values
# themselves come from dev.tfvars / prod.tfvars passed with -var-file=...
