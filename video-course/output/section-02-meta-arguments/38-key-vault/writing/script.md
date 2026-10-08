# Script — Lab 38: Secrets with Nowhere to Hide: Azure Key Vault

*Terraform Meta-arguments — Lab 38. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/38-key-vault`).*

---

## S001 — TITLE: Secrets with Nowhere to Hide: Azure Key Vault

**Secrets with Nowhere to Hide: Azure Key Vault**

Welcome back. After five fan-out labs, a change of pace — and a change of subject: secrets. This is Lab 38, and we build a Key Vault with Terraform: a data source that reads who's signed in, a vault with an access policy, and a secret whose value comes from an input — never from the source code. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- A data source: azurerm_client_config reads who is signed in
- The vault + a nested access_policy block granting YOUR user access
- Secret value from a sensitive variable; sensitive output redacts

**What you'll learn**

Three things in this lesson. One: your first data source in this section — azurerm client config, which reads facts about the signed-in principal instead of creating anything. Two: the vault itself, with a nested access policy block that grants your user the secret permissions. Three: the secret-handling pattern — the value comes from a required sensitive variable, and the output is marked sensitive so the CLI redacts it.

---

## S003 — CONCEPT: Where this lab fits

- Section 1, lab 20: secret VALUES belong in inputs, not source
- This lab: the first data source + nested access_policy
- Next lab: data sources get a full episode of their own

**Where this lab fits**

Placement. Back in section 1, lab 20 established the rule: secret values come from inputs, never from source code. This lab puts that rule to work for real — a vault that stores the secret centrally. You also meet the first data source of section 2; the very next lab gives data sources a full episode. And note the random provider returns — it earned its keep in section 1 and does again here.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 38-key-vault

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/38-key-vault
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 38-key-vault. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins both providers.

---

## S005 — CODE

Terraform dot T F first. It pins Terraform 1.5 or newer, and TWO providers this time: azurerm around version 3.70 for Azure, and random around 3.6 — this lab needs a stable random suffix, which we'll see why shortly. The provider block at the bottom bridges to Azure with the standard empty features block.

---

## S006 — CODE

**Steps:**

1. The secret enters the same way it did in section 1: a variable called db password — required, no default, marked sensitive. Terraform prompts for it, or you pass it with dash var. The source code never sees a secret literal — and that's the whole point.
   - active: [11, 12, 13, 14]

The secret enters the same way it did in section 1: a variable called db password — required, no default, marked sensitive. Terraform prompts for it, or you pass it with dash var. The source code never sees a secret literal — and that's the whole point.

---

## S007 — CODE

**Steps:**

1. Here's the data source — and its emptiness is the point. data azurerm client config, current, with an empty body. It creates nothing; it reads facts about whoever is signed in with az login: the tenant id and the object id — your user's identity in Azure AD.
   - active: [17]

Here's the data source — and its emptiness is the point. data azurerm client config, current, with an empty body. It creates nothing; it reads facts about whoever is signed in with az login: the tenant id and the object id — your user's identity in Azure AD.

---

## S008 — CODE

**Steps:**

1. The vault needs a globally unique name, 3 to 24 characters, alphanumerics and hyphens only. Locals builds it: kv dash, then a random suffix.
   - active: [20, 21, 22, 23]
2. And the suffix comes from the random provider — resource random string, six characters, no uppercase, no specials. The comment explains why it's a resource and not a function trick: the value is SAVED in state, so every plan and apply is stable — nothing gets unexpectedly replaced.
   - active: [28, 29, 30, 31, 32]

The vault needs a globally unique name, 3 to 24 characters, alphanumerics and hyphens only. Locals builds it: kv dash, then a random suffix. And the suffix comes from the random provider — resource random string, six characters, no uppercase, no specials. The comment explains why it's a resource and not a function trick: the value is SAVED in state, so every plan and apply is stable — nothing gets unexpectedly replaced.

---

## S009 — CODE

**Steps:**

1. The resource group — rg dash kv dash meta. The usual container, nothing new here.
   - active: [35, 36, 37, 38]

The resource group — rg dash kv dash meta. The usual container, nothing new here.

---

## S010 — CODE

**Steps:**

1. The vault itself. Name from locals, standard SKU, and two settings worth pausing on: soft delete retention of 7 days — deleted secrets stay recoverable for a week — and purge protection off, which is fine for a lab but belongs ON in production.
   - active: [42, 43, 47, 48, 49]
2. Tenant id comes straight from the data source — data dot azurerm client config dot current dot tenant id. The vault belongs to the tenant of whoever ran az login. The data source is doing real work already.
   - active: [46]
3. And the nested block: access policy. It grants a principal — here, you, via object id from the same data source — five secret permissions: get, list, set, delete, purge. Whoever deployed this vault can read and write its secrets.
   - active: [51, 52, 53, 54, 55, 56]

The vault itself. Name from locals, standard SKU, and two settings worth pausing on: soft delete retention of 7 days — deleted secrets stay recoverable for a week — and purge protection off, which is fine for a lab but belongs ON in production. Tenant id comes straight from the data source — data dot azurerm client config dot current dot tenant id. The vault belongs to the tenant of whoever ran az login. The data source is doing real work already. And the nested block: access policy. It grants a principal — here, you, via object id from the same data source — five secret permissions: get, list, set, delete, purge. Whoever deployed this vault can read and write its secrets.

---

## S011 — CODE

**Steps:**

1. The secret resource. Its name is db password; its value line is the one to read carefully: value equals var dot db password. The value comes from the input — there is no secret literal anywhere in this source.
   - active: [61, 62, 63]
2. Key vault id points at the vault we just created — the secret lives inside it. And be honest about the limit: the value still lands in Terraform state in plain text. Sensitive hides the CLI output, not the state file — the README gotchas say this plainly.
   - active: [64]

The secret resource. Its name is db password; its value line is the one to read carefully: value equals var dot db password. The value comes from the input — there is no secret literal anywhere in this source. Key vault id points at the vault we just created — the secret lives inside it. And be honest about the limit: the value still lands in Terraform state in plain text. Sensitive hides the CLI output, not the state file — the README gotchas say this plainly.

---

## S012 — CODE

**Steps:**

1. Two outputs. Vault name is plain — a name is not a secret. The second output is the secret's versionless id, marked sensitive equals true.
   - active: [69, 71, 72, 73, 74]
2. Notice what's output and what isn't: the ID of the secret — a stable reference other configs can use — never the secret's value. The value leaves the vault only through the access policy, not through Terraform outputs.
   - active: [70, 71, 72]

Two outputs. Vault name is plain — a name is not a secret. The second output is the secret's versionless id, marked sensitive equals true. Notice what's output and what isn't: the ID of the secret — a stable reference other configs can use — never the secret's value. The value leaves the vault only through the access policy, not through Terraform outputs.

---

## S013 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The sensitive variable carries the secret value in.
   - active: ['vars']
3. The data source reads who is signed in — tenant id and object id, creating nothing.
   - active: ['data']
4. Random string makes a stable six-character suffix.
   - active: ['random']
5. The resource group groups everything in Azure.
   - active: ['rg']
6. The vault: named with the random suffix, owned by the data source's tenant, with an access policy granting YOUR object id five permissions.
   - active: ['vault']
7. The secret stores the variable's value inside the vault.
   - active: ['secret']
8. Everything lands inside your Azure subscription.

Here's how the pieces connect. The sensitive variable carries the secret value in. The data source reads who is signed in — tenant id and object id, creating nothing. Random string makes a stable six-character suffix. The resource group groups everything in Azure. The vault: named with the random suffix, owned by the data source's tenant, with an access policy granting YOUR object id five permissions. The secret stores the variable's value inside the vault. Everything lands inside your Azure subscription.

---

## S014 — TERMINAL

Here's the plan — terraform plan, an illustrative view. The random suffix, the resource group, the vault, and the secret — whose value shows as sensitive value, redacted. Four to add, zero to destroy. The data source appears in the refresh step, not as a resource to create.

---

## S015 — TERMINAL

And the outputs — terraform output, an illustrative view. Vault name shows plainly: kv dash, then the random suffix. The secret's id prints as sensitive value — redacted in the CLI, exactly as the sensitive flag promised.

---

## S016 — CONCEPT: Common pitfall

- Soft delete: recreating the vault within 7 days fails unless purged
- sensitive hides CLI output — the value is still plaintext in state
- The access policy follows az login — whoever deployed gets access

**Common pitfall**

Three pitfalls. One: soft delete cuts both ways — destroy the vault and re-apply within seven days, and the create fails with a name conflict until you purge the soft-deleted vault or wait. Two: sensitive equals true redacts plan and apply output — it does NOT encrypt state; the secret value sits in the state file in plain text, so protect that file like the secret it holds. Three: the access policy is tied to whoever ran az login at deploy time — their object id is hard-wired into the policy; teammates get access only when the policy includes them too.

---

## S017 — RECAP

- data "azurerm_client_config" reads the signed-in principal — creates nothing
- random_string is stateful: saved in state, stable across applies
- access_policy: a nested block granting YOUR object_id permissions
- value = var.db_password — no secret literal in the source
- sensitive = true redacts CLI output; state stays plaintext

Quick recap — five things. One: the client config data source reads who's signed in and creates nothing. Two: random string is a stateful resource — saved in state, stable across applies. Three: the access policy is a nested block that grants your object id five secret permissions. Four: the secret's value comes from a sensitive input — no literal in the source. Five: sensitive redacts the CLI, not the state file. Secrets belong in a vault, values belong in inputs — and now you've built both halves.

---

## S018 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S019 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/38-key-vault
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
