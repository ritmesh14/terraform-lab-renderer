# The Moved Block

**Episode:** section-01-foundations/23-moved-block
**Lesson label:** Azure Foundations — Lab 23
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/23-moved-block
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: The Moved Block

Names change. A resource block called legacy becomes this, and the code reads better — but Terraform only knows addresses. Rename without telling it, and it destroys the old resource and builds a new one. The moved block renames the address without touching the real thing.

## S002 — CONCEPT: What you'll learn

- moved {}: rename a resource address with no destroy and no create
- Terraform rewrites the state address in place
- from the old address, to the new address
- Remove the block after the rename has been applied everywhere

Here's what you'll learn. One: the moved block — rename a resource address with no destroy and no create. Two: Terraform rewrites the state address in place. Three: from the old address, to the new address. Four: remove the block after the rename has been applied everywhere.

## S003 — CONCEPT: Where this lab fits

- Lab 23 of the Foundations section
- Lab 05 covered depends_on; lab 22 adopted existing resources
- Renaming addresses is routine refactoring — moved makes it safe

This is lab twenty-three, and it's about code hygiene rather than new cloud pieces. As configurations grow, you rename blocks for clarity — web becomes legacy, generic becomes specific. The danger isn't the rename. It's what Terraform does with an unexplained rename: destroy and recreate. Today's block prevents exactly that.

## S004 — CONCEPT: Addresses are the identity — until you say otherwise

- Terraform tracks resources by config address, not by name string
- Rename without moved{} = destroy old + create new
- moved { from = … , to = … } rewrites the state address in place
- The real Azure resource is never replaced — nothing is recreated

The mental model: Terraform's identity for a resource is its address — the type plus the label. Rename the block, and the address changes. Without an explanation, Terraform assumes the old one died and a new one appeared: destroy, then create. The moved block is the explanation. From equals the old address, to equals the new one — and Terraform rewrites state in place. Same real resource, new name.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 23-moved-block
              ├── README.md
              └── main.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/23-moved-block
```

The lab is in the course GitHub repository under Section 1, Foundations, link in the description. Just a readme and main dot t f — the moved story is small and self-contained.

## S006 — CODE: main.tf lines 30-44

The foundation: locals with a slash-twenty VNet — four thousand ninety-six addresses — and a slash-twenty-six subnet, just sixty-four. Smaller slices than we've used before, to show the sizes are your choice. And a random suffix — stateful, so it stays stable across every plan.

## S007 — CODE: main.tf lines 46-66

The stack: resource group, VNet, subnet — all wired the usual way. Nothing new here, and that's deliberate. The moved block doesn't care what the resources are; it only cares about their addresses. Any resource in this configuration could be renamed the same way.

## S008 — CODE: main.tf lines 68-86

The heart of the lesson. The storage account sits at its new address, this. And the moved block: from azurerm storage account legacy, to azurerm storage account this. If state holds the resource under the old name, Terraform rewrites the address — no destroy, no create. The output prints the name the real account kept all along.

## S009 — DIAGRAM: Same resource, new address

The move, drawn out: the old address, legacy, is what state used to hold. The moved block translates it — from legacy, to this. And the real storage account in Azure is untouched — same resource, same data, same name. Only the state address changed.

## S010 — TERMINAL: terraform apply

Plan time — and the line that matters: azurerm storage account legacy has moved to azurerm storage account this. Zero to add, zero to change, zero to destroy. The apply's summary says it plainly: nothing was touched in Azure. The state simply points at the same account under its new name.

## S011 — CONCEPT: Common pitfall — renaming without moving

- Renaming a block address is a destroy + create unless declared
- moved {} only rewrites the state address — never the resource
- Storage account renames are different: Azure names can't change in place
- Remove moved{} once every environment has applied the rename

Here are the pitfalls in this lab. One: renaming a block address means a destroy and create — unless it's declared. Without the moved block, Terraform sees a deleted resource and a brand-new one — and for a storage account, the data inside it goes with the old one. Two: the moved block only rewrites the state address — never the resource. It's safe precisely because nothing in Azure changes. Three: storage account renames are different — Azure names can't change in place. Moving the address is safe; the name string itself is immutable in Azure. Four: remove the moved block once every environment has applied the rename. It's scaffolding — clean it up after it has done its job.

## S012 — RECAP: recap

- moved { from, to } renames a resource address safely
- State address rewritten in place — 0 add, 0 change, 0 destroy
- Without it, a rename means destroy + create of the real resource
- Works for renames, module moves, and count/for_each changes
- Clean the block up once the rename has landed everywhere

Quick recap — five things. One: the moved block — from the old address, to the new one — renames a resource address safely. Two: the state address is rewritten in place — zero adds, zero changes, zero destroys. Three: without it, a rename means destroy and create of the real resource. Four: it works for renames, module moves, and count or for each changes. Five: clean the block up once the rename has landed everywhere.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/23-moved-block
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
