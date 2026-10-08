# Section 3 — Web apps and databases

Move from VMs to managed platforms. Deploy Azure App Service and its deployment slots,
apply lifecycle rules and resource tags, then provision an Azure SQL Database (with
firewall rules) and a MySQL server, and finally wire a web app to its database.

## How to use these labs

Prerequisites (once, on your machine):

- **Terraform >= 1.5** — check with `terraform -version`
- **Azure CLI** — check with `az --version`
- **Sign in to Azure** — run `az login` before the first `terraform apply` in a
  session; Terraform uses that identity to create resources. If you have more
  than one subscription, pick one with `az account set --subscription "<name>"`.

Typical flow for every lab (run from inside the lab folder):

```bash
cd 51-web-app          # pick the lab
terraform init         # first time only: download providers
terraform plan         # preview what will be created/changed
terraform apply        # create it (type "yes" to confirm)
terraform output       # print values such as the site URL
terraform destroy      # clean up and stop paying for the lab
```

Labs marked *(assignment)* are self-checks: try them before reading the solution
in `main.tf`. Some labs need a `terraform.tfvars` (see the `terraform.tfvars.example`
file in the lab folder — copy it and fill in a real password or your client IP),
and lab 61 authors a `schema.sql` that lab 63 runs manually.

## Labs

51. [Azure Web App](51-web-app/)
52. [Deploying another web app](52-another-web-app/) *(assignment)*
53. [The `lifecycle` meta-argument](53-lifecycle/)
54. [Resource tags](54-resource-tags/)
55. [Deployment slots — create](55-deployment-slots-create/)
56. [Deployment slots — swap](56-deployment-slots-swap/)
57. [App Service logs](57-app-service-logs/)
58. [Azure SQL Database](58-sql-database/)
59. [SQL Database — firewall rules](59-sql-firewall-rules/)
60. [Change the SQL DTU model](60-change-sql-dtu/) *(assignment)*
61. [Deploying another SQL Database — prepare](61-another-sql-prepare/)
62. [Deploying another SQL Database — deploy](62-another-sql-deploy/)
63. [Adding data to an Azure SQL database](63-sql-add-data/)
64. [Connecting a web app to SQL](64-web-app-to-sql/)
65. [Mini project — MySQL server](65-mysql-server/)
66. [Mini project — configure MySQL](66-mysql-configure/)
67. [Mini project — deploy the web app](67-web-app-deploy/)
68. [Mini project — VNet integration](68-web-app-vnet-integration/)

## Advanced labs

69. [App Service auto-scale](69-app-service-autoscale/)
70. [App Service source control (Git deploy)](70-app-service-source-control/)
71. [Azure SQL with Entra ID admin](71-sql-entra-admin/)
72. [MySQL — configuration & high availability](72-mysql-parameters/)
