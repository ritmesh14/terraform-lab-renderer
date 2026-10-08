# Lab 96 — Application Gateway — SSL termination via Key Vault (advanced)

Terminate HTTPS on the gateway with a **self-signed certificate stored in Key Vault**.
App Gateway fetches the cert from the vault using a **user-assigned managed identity** —
the cert never sits in the repo, and no certificate material ever appears in your
Terraform code or state.

Steps in code:
1. Key Vault (with an access policy).
2. A self-signed cert generated **by Key Vault** (`issuer { name = "Self" }`) and stored as
   a PFX secret.
3. A user-assigned identity, granted `Get` on the cert secret in the vault.
4. App Gateway v2 with that identity, an HTTPS listener on 443, and an
   `ssl_certificate` pointing at `key_vault_secret_id`.

Addressing: VNet `172.25.0.0/20`; gateway subnet `172.25.0.0/26`; backend subnet
`172.25.0.64/26`.

> Browsers will warn about the self-signed cert — that's expected; it's a learning lab.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-appgw-ssl` | eastus |
| `azurerm_key_vault` | `kv-appgwssl-<suffix>` | Stores the cert |
| `azurerm_key_vault_access_policy` × 2 | — | You (manage certs) + the gateway identity (Get) |
| `azurerm_user_assigned_identity` | `id-appgw-ssl` | Used by the gateway |
| `azurerm_key_vault_certificate` | `appgw-ssl-cert` | Self-issued, PFX, CN=appgw-ssl.local |
| `azurerm_virtual_network` / subnets / NIC / VM | `vnet-appgw-ssl` etc. | 1 nginx backend |
| `azurerm_public_ip` | `pip-appgw-ssl` | Gateway frontend |
| `azurerm_application_gateway` | `appgw-ssl` | HTTPS listener 443, cert from Key Vault |

## Commands

Prerequisite: `az login` (the lab reads your tenant/object id via
`data "azurerm_client_config"` to grant you vault access). Needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/96-app-gateway-ssl
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 14 resources to add
terraform apply   # allow a few minutes — the gateway is slow to provision
terraform output  # appgw_public_ip
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-appgw-ssl** → **kv-appgwssl-\<suffix\> → Certificates**:
  `appgw-ssl-cert`, issuer **Self**.
- **appgw-ssl → Settings → SSL certificates**: shows the Key Vault cert reference —
  there is no uploaded .pfx file.
- **Listeners**: `listener-https` on port 443, protocol Https.
- Browse `https://<appgw_public_ip>`: accept the browser's certificate warning
  (self-signed), then the gateway terminates TLS and proxies plain HTTP to the nginx VM.

## Key concepts / gotchas

- **SSL termination**: clients speak HTTPS to the gateway; the gateway decrypts and talks
  plain HTTP to the backends — the backends never need certs.
- **Key Vault + managed identity** is the modern way to store gateway certs: the
  `identity` block on the gateway plus the vault's access policy for that identity are
  what authorize the fetch; Terraform only ever stores a *reference*
  (`key_vault_secret_id`).
- `depends_on = [azurerm_key_vault_access_policy.user]` matters: Terraform can't create
  the certificate before the vault grants *your* account access — an explicit ordering
  fix for an implicit dependency Terraform can't infer from data.
- `random_string` suffix makes the globally-unique vault name reproducible (stored in
  state, not re-rolled on every apply).
- v2 gateways **require** Key Vault certs for HTTPS when using identity-based
  certificate references; the legacy path is uploading the .pfx directly.
