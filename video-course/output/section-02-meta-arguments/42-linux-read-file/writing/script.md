# Script — Lab 42: Reading the Disk: file() and fileexists()

*Terraform Meta-arguments — Lab 42. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/42-linux-read-file`).*

---

## S001 — TITLE: Reading the Disk: file() and fileexists()

**Reading the Disk: file() and fileexists()**

Welcome back. Until now, every SSH key arrived as a typed variable. This is Lab 42, and the key comes from somewhere new: the filesystem. fileexists guards, file reads, and a ternary picks — so the lab works with your key when id_rsa dot pub is present, and falls back gracefully when it isn't. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- file("id_rsa.pub") reads the lab folder AT PLAN TIME
- fileexists() ? file() : fallback — the ternary guards a missing file
- filebase64() and templatefile() — the same family, one step up

**What you'll learn**

Three things in this lesson. One: the file function — it reads a file from the module's folder at plan time, and its CONTENT becomes part of the configuration. Two: the guard — fileexists checks first, and the ternary operator picks between the real key and a placeholder, so a missing file is a graceful fallback instead of a hard error. Three: the wider family — filebase64 reads bytes, and templatefile injects values into a templated script; both are the same idea one step up.

---

## S003 — CONCEPT: Where this lab fits

- Labs 35/40: the single-VM stack, key supplied as a sensitive VARIABLE
- This lab: the same stack, key read from id_rsa.pub on disk
- Lab 43 takes this exact VM and restructures the files

**Where this lab fits**

Placement. The single-VM stack is familiar from labs 35 and 40 — VNet, subnet, NIC, VM. The change here is the key's source: instead of a required sensitive variable, it's read from a file on disk. And this exact configuration is the one lab 43 will restructure into multiple files — so the resource shape you see today is the one you'll split tomorrow.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 42-linux-read-file

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/42-linux-read-file
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 42-linux-read-file. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults.

---

## S006 — CODE

**Steps:**

1. The guard: fileexists of id_rsa dot pub. True or false, evaluated at plan time — it protects against the file being absent, which would otherwise be a hard error that stops the plan.
   - active: [10, 11, 12]
2. Then the ternary: question mark, and the two branches. If the file exists, file() reads its CONTENT — the whole key lands in local dot ssh pubkey. If not, the fallback placeholder string keeps the config valid; the VM deploys, just with a key nobody can log in with.
   - active: [12, 13]

The guard: fileexists of id_rsa dot pub. True or false, evaluated at plan time — it protects against the file being absent, which would otherwise be a hard error that stops the plan. Then the ternary: question mark, and the two branches. If the file exists, file() reads its CONTENT — the whole key lands in local dot ssh pubkey. If not, the fallback placeholder string keeps the config valid; the VM deploys, just with a key nobody can log in with.

---

## S007 — CODE

**Steps:**

1. The network base is the standard single-VM shape: resource group rg dash linux dash readfile, VNet on 10.230 slash 16, subnet snet web on 10.230.1 slash 24.
   - active: [17, 26, 34]

The network base is the standard single-VM shape: resource group rg dash linux dash readfile, VNet on 10.230 slash 16, subnet snet web on 10.230.1 slash 24.

---

## S008 — CODE

**Steps:**

1. The NIC: nic dash readfile, dynamic private IP inside the subnet. One NIC, one VM — no fan-out this time; the lesson is the file read, not the meta-arguments.
   - active: [38, 39, 44]

The NIC: nic dash readfile, dynamic private IP inside the subnet. One NIC, one VM — no fan-out this time; the lesson is the file read, not the meta-arguments.

---

## S009 — CODE

**Steps:**

1. The VM: vm dash readfile, standard burstable size, admin username azureadmin, NIC from the block above.
   - active: [51, 56]
2. And the line the lab exists for: public key equals local dot ssh pubkey. That value was read from disk at plan time — or fell back to the placeholder. The VM trusts whatever the ternary produced; the file is now part of the configuration.
   - active: [57, 58, 59]
3. Below, the two nested blocks you know by heart: os disk on standard SSD, and the Ubuntu 22.04 source image reference — identical to labs 35 through 40.
   - active: [61, 65]

The VM: vm dash readfile, standard burstable size, admin username azureadmin, NIC from the block above. And the line the lab exists for: public key equals local dot ssh pubkey. That value was read from disk at plan time — or fell back to the placeholder. The VM trusts whatever the ternary produced; the file is now part of the configuration. Below, the two nested blocks you know by heart: os disk on standard SSD, and the Ubuntu 22.04 source image reference — identical to labs 35 through 40.

---

## S010 — CONCEPT: file() reads at plan time

- The read happens on the machine running Terraform — not in Azure
- The content is frozen into the plan: same file, same plan
- Change id_rsa.pub and the VM is flagged for replacement

**file() reads at plan time**

Worth pausing on WHEN the read happens. File functions run on the machine running Terraform, at plan time — not inside Azure, not at apply. The content is hashed into the plan, so the same file always produces the same plan. And the flip side: edit id_rsa dot pub and Terraform sees a changed argument — the VM is flagged for replacement, exactly like custom_data in lab 40. The file isn't a reference; it's now part of the config.

---

## S011 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. Locals read the key from id_rsa dot pub on disk — or fall back to the placeholder.
   - active: ['locals']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The network: VNet and subnet at 10.230.1.0 slash 24.
   - active: ['vnet']
5. The NIC attaches to the subnet with a dynamic private IP.
   - active: ['nic']
6. And the VM: NIC attached, and its SSH key is the file content read in locals.
   - active: ['vm']
7. Everything lands inside your Azure subscription.

Here's how the pieces connect. Locals read the key from id_rsa dot pub on disk — or fall back to the placeholder. The resource group groups everything in Azure. The network: VNet and subnet at 10.230.1.0 slash 24. The NIC attaches to the subnet with a dynamic private IP. And the VM: NIC attached, and its SSH key is the file content read in locals. Everything lands inside your Azure subscription.

---

## S012 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Resource group, VNet, subnet, NIC, VM — five to add, zero to destroy. The SSH key in the plan came from the file read — plan time, not apply time.

---

## S013 — TERMINAL

And the state list — terraform state list, an illustrative view. Five resources, the complete single-VM stack. No outputs in this lab — the private IP and the key live in state, and the SSH target is your local id_rsa half.

---

## S014 — CONCEPT: Common pitfall

- The path is relative to the module folder — running plan from elsewhere changes the lookup
- The placeholder fallback deploys a key nobody can use — check which branch ran
- Editing id_rsa.pub flags the VM for replacement — the content is in the config

**Common pitfall**

Three pitfalls. One: the path is relative to the module's working directory — run the plan from another folder and the lookup changes with you; that surprises everyone once. Two: the fallback is graceful, which cuts both ways — a VM running with the placeholder key accepts a private key nobody owns; if you can't SSH in, check WHICH branch of the ternary ran. Three: because the content becomes part of the config, replacing id_rsa dot pub isn't a harmless refresh — Terraform flags the VM for replacement on the next plan.

---

## S015 — RECAP

- file("id_rsa.pub") reads the lab folder at plan time
- fileexists() guards the read; the ternary picks file vs fallback
- The content lands in local.ssh_pubkey → admin_ssh_key.public_key
- Same file → same plan; edit the file → VM flagged for replacement
- filebase64() / templatefile() are the same family, one step up

Quick recap — five things. One: file() reads a file from the module folder at plan time. Two: fileexists guards it, and the ternary picks the read or the placeholder — graceful, not fatal. Three: the content flows into the VM's SSH key through locals. Four: the read is frozen into the plan — changing the file flags the VM for replacement. Five: the family grows from here — filebase64 for bytes, templatefile for templated scripts. Terraform can now read your disk.

---

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S017 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/42-linux-read-file
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
