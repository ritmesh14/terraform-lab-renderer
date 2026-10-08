# Importing Existing Resources

**Episode:** section-01-foundations/22-terraform-import
**Lesson label:** Azure Foundations — Lab 22
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/22-terraform-import
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Importing Existing Resources

Every resource we've built so far was created by Terraform. But real projects inherit resources that already exist — created by hand, by script, by a teammate. This lesson adopts one of those into Terraform state, without creating or destroying anything.

## S002 — CONCEPT: What you'll learn

- terraform import: bring an existing Azure resource under management
- The declarative import block — Terraform 1.5 and later
- The Azure resource id format: subscriptions, resource groups, providers
- Adopt first, manage forever after — no recreate, no downtime

Here's what you'll learn. One: terraform import — bring an existing Azure resource under management. Two: the declarative import block — Terraform one point five and later. Three: the Azure resource I D format — subscriptions, resource groups, providers. Four: adopt first, manage forever after — no recreate, no downtime.

## S003 — CONCEPT: Where this lab fits

- Lab 22 of the Foundations section
- Labs 02 through 21: every resource was created from scratch
- Real teams inherit hand-made resources every day — import is the bridge

This is lab twenty-two, and it breaks a pattern we've kept for twenty labs: nothing here gets created. There's a storage account in Azure already — made with the command line, outside Terraform. Our job is to adopt it, so future changes go through Terraform like everything else.

## S004 — CONCEPT: Adoption, not creation

- The import block binds an existing resource id to a config address
- Nothing is created or destroyed — state gains the binding
- After import, Terraform manages the resource like any other
- Needs Terraform 1.5+ for the declarative import block

The mental model: adoption, not creation. An import block names two things — an Azure resource id, and an address in the configuration. On the next apply, Terraform reads the real resource and records it in state under that address. Nothing changes in Azure. From then on, the resource answers to Terraform.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 22-terraform-import
              ├── README.md
              ├── main.tf
              ├── variables.tf
              └── terraform.tfvars.example

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/22-terraform-import
```

The lab is in the course GitHub repository under Section 1, Foundations, link in the description. The readme shows how to create the example storage account first — main dot t f then adopts it.

## S006 — CODE: main.tf lines 25-42

First, the ingredients of the resource id. The data source reads our current subscription. Two variables name the existing account and its resource group. And the local builds the full Azure id — subscriptions, resource groups, providers, storage accounts. Every Azure resource has an id in exactly this shape.

## S007 — CODE: main.tf lines 44-50

The import block — three lines that do the adoption. To: the address in our configuration. Id: the Azure resource id we just built. On the next apply, Terraform reads the real account and binds it to this address — no creation, no destruction, just state gaining an entry.

## S008 — CODE: main.tf lines 52-63

And the resource block that describes what the account should look like. After the import, Terraform compares this desired state against the real resource — any drift shows up in the next plan. The output prints the adopted id, which should match the local we built earlier.

## S009 — DIAGRAM: Adoption path: existing resource into state

Drawn out: the storage account lives in Azure, created by hand. The import block carries its full resource id, and points at the configuration address. On apply, Terraform reads the real resource — and records it in state under that address. Azure never changed. Management did.

## S010 — TERMINAL: terraform apply

Apply time — and the verb is different. Not seven added: one imported, zero added, zero changed, zero destroyed. Terraform read the existing account and wrote it into state. The next plan will compare our resource block against the real account — and manage every future change.

## S011 — CONCEPT: Common pitfall — importing without a matching block

- The CLI form imports into state — you still write the resource block yourself
- A config that doesn't match the real resource shows drift on the next plan
- The id must be the FULL Azure resource id — not just the name
- Import binds; it never fixes a wrongly-typed resource block

Here are the pitfalls in this lab. One: the c l i form imports into state — you still write the resource block yourself. Import only creates the state binding; the configuration still has to describe the resource correctly. Two: a config that doesn't match the real resource shows drift on the next plan. If the block says standard l r s but the real account is standard g r s, the next plan shows the difference. Three: the i d must be the full Azure resource i d — not just the name. Subscription, resource group, provider, type, and name — that's why the lab builds it in a local. Four: import binds — it never fixes a wrongly-typed resource block. If the block is wrong, fix the block; import won't correct it.

## S012 — RECAP: recap

- import {} block (Terraform 1.5+): bind existing id to config address
- Nothing created or destroyed — state gains the binding
- Azure resource id: /subscriptions/<sub>/resourceGroups/<rg>/providers/…
- The resource block must match reality — drift shows on the next plan
- CLI form: terraform import ADDRESS ID — one-off alternative

Quick recap — five things. One: the import block — Terraform one point five and later — binds an existing i d to a config address. Two: nothing is created or destroyed — state gains the binding. Three: the Azure resource i d reads subscriptions, resource groups, providers — the full path. Four: the resource block must match reality — drift shows on the next plan. Five: the c l i form — terraform import, address, i d — is the one-off alternative.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/22-terraform-import
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
