# Lab 37 keeps its variable declarations in main.tf: this file used to declare the
# same variable twice, and Terraform rejects a duplicate variable declaration.
# Variable declarations moved to main.tf (they were declared twice, which Terraform rejects).
