# 03 — Upload a Blob

Create a storage account, a container, and upload a small text file as a block blob
using `azurerm_storage_blob`. This is the first lab that chains three resources in an
implicit dependency order: resource group → storage account → container → blob.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-blob-foundation` | Container for the lab |
| `azurerm_storage_account.this` | `stblobfound<suffix>` | Standard tier, LRS |
| `azurerm_storage_container.uploads` | `uploads` | Private access |
| `azurerm_storage_blob.hello` | `hello.txt` | Block blob, uploaded inline |

## What you learn

- `azurerm_storage_container` controls blob grouping + access tier.
- `azurerm_storage_blob` with `source` uploads a local file.
- The `source_content` argument accepts inline bytes; `source` accepts a file path.

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/03-upload-blob
terraform init
terraform plan
terraform apply
terraform output blob_url
```

Then inspect the uploaded blob:

```bash
az storage blob show --account-name <name> --container-name uploads --name hello.txt
```

Clean up when done:

```bash
terraform destroy
```

## What to see in the Azure portal

Open the portal → **Resource groups** → `rg-blob-foundation` → click the storage
account (starts with `stblobfound`) → **Storage browser → Blob containers → uploads**.
You should see `hello.txt`. Click **View/edit** to read the text
`Hello from Terraform! Uploaded: <timestamp>`.

## Key concepts / gotchas

- `container_access_type = "private"` is the safe default — blobs are readable only by
  authorized requests, so `blob_url` alone 404s in a browser (no SAS token).
- `source_content` embeds the file text in the Terraform config itself; use `source =
  "./file.png"` for real files.
- **The timestamp() gotcha**: because `timestamp()` sits inside `source_content`, its
  value is frozen into Terraform state at apply time. On the next `plan`, time has moved
  on, so Terraform shows the blob wanting an in-place update on *every* run. Harmless in
  a lab, and a deliberate demo of the rule: keep volatile functions out of attributes
  that are diffed against state unless you want drift every run.
- `timestamp()` is read at plan time, not apply time — another reason it churns.