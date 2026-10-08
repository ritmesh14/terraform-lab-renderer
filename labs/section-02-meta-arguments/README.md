# Section 2 — Meta-arguments and repetition

Real infrastructure has many similar resources. This section shows the two repetition
meta-arguments — `count` and `for_each` — then adds resilience (availability sets/zones),
secrets (Key Vault), flexibility (dynamic blocks), post-creation actions (provisioners),
and secure access (Azure Bastion).

## How to use these labs

**Prerequisites**

- **Terraform >= 1.5** — `terraform -version` to check.
- **Azure CLI** (`az`) installed and signed in: `az login` (each lab talks to your
  subscription; labs 38 and 39 additionally use the signed-in identity).
- A subscription where you can create/destroy resource groups. All resources in these
  labs are cheap lab sizes (`Standard_B1s`) — run `terraform destroy` when done.

**Typical command flow** (inside a lab folder):

```bash
cd 26-count-meta-argument          # pick a lab folder
terraform init                     # download providers (once per lab)
terraform plan                     # preview exactly what will be created
terraform apply                    # create it (type "yes" to confirm)
terraform output container_names   # read results
terraform destroy                  # delete everything the lab created
```

Pass inputs with `-var=name=value` or a `terraform.tfvars` file when a lab needs them
(SSH keys, passwords, existing resource-group names). Each lab's README lists its
variables and what to click in the Azure portal.

## Labs

26. [The `count` meta-argument](26-count-meta-argument/)
27. [Multiple storage containers](27-multiple-containers/)
28. [The `for_each` meta-argument](28-for-each-meta-argument/)
29. [`for_each` over blobs](29-for-each-blobs/)
30. [Multiple subnets](30-multiple-subnets/)
31. [Multiple network interfaces](31-multiple-nics/) *(assignment)*
32. [Multiple public IPs](32-multiple-public-ips/)
33. [`for_each` + variables](33-for-each-variables/)
34. [Network Security Groups](34-network-security-groups/)
35. [Multiple virtual machines](35-multiple-vms/)
36. [Availability Sets](36-availability-sets/)
37. [Availability Zones](37-availability-zones/)
38. [Azure Key Vault](38-key-vault/)
39. [Data sources](39-data-sources/)
40. [Web server via Terraform](40-web-server/)
41. [Dynamic blocks](41-dynamic-blocks/)
42. [Linux machine — read a local file](42-linux-read-file/)
43. [Linux machine — restructure](43-linux-restructure/)
44. [Linux machine — deployment](44-linux-deployment/)
45. [Provisioners](45-provisioners/)
46. [Azure Bastion](46-azure-bastion/)

## Advanced labs

47. [Conditional resources (feature flags)](47-conditional-resources/)
48. [`flatten()` — nested structures into a list](48-flatten-matrix/)
49. [`for_each` over a data source](49-for-data-sources/)
50. [Dynamic blocks at multiple levels](50-dynamic-multi/)
