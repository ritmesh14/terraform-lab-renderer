# Variable declarations moved to main.tf (they were declared twice, which Terraform rejects).
# The only variable in this lab is `ssh_public_key` (declared in main.tf,
# sensitive). Supply it by copying terraform.tfvars.example to terraform.tfvars
# and filling in your real public key — tfvars files with secrets stay out of git.
