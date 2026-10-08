# Public IP Addresses

**Episode:** section-01-foundations/15-public-ip
**Lesson label:** Azure Foundations — Lab 15
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/15-public-ip
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Public IP Addresses

Everything we've built so far is private — VNets, subnets, a network interface with a private address. This lesson adds the doorway from the internet: the public I P, and the two settings that decide whether that address ever changes.

## S002 — CONCEPT: What you'll learn

- azurerm_public_ip: a resource's doorway from the internet
- allocation_method: Static keeps the address, Dynamic releases it
- sku: Basic is legacy — Standard is the modern default
- The address is computed — read via output after apply

Here's what you'll learn. One: azurerm public I P — a resource's doorway from the internet. Two: allocation method — static keeps the address, dynamic releases it. Three: S K U — Basic is legacy; Standard is the modern default. Four: the address is computed — read it via an output after apply.

## S003 — CONCEPT: Where this lab fits

- Lab 15 of the Foundations section
- Lab 13's NIC has a private IP only — nothing reachable from outside
- Next lab (NSG) decides who's allowed through this door

This is lab fifteen. Lab thirteen gave a network interface a private address — reachable inside the VNet, invisible from the internet. Today we add the doorway. And a doorway is only half the story: the next lesson adds the doorman, the security rules that decide who's let through.

## S004 — CONCEPT: Static vs Dynamic, Basic vs Standard

- Dynamic: released when the resource stops — the address changes
- Static: reserved for the resource's lifetime — survives stop/start
- Basic SKU: legacy; Standard: required for zone-redundant load balancers
- A public IP is a real resource: created, referenced, billed

Two decisions define every public I P. Allocation: dynamic addresses are handed out cheaply but released when the machine stops — bookmarks and D N S records break. Static reserves the address for the resource's lifetime. Then S K U: Basic is the legacy tier, Standard is today's default and what zone-redundant load balancers require. And note the shape: a public I P is a resource of its own — created, referenceable, and billed.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 15-public-ip
              ├── README.md
              ├── main.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/15-public-ip
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. One of the smallest labs in the section — one group, one address — because the lesson is in two settings.

## S006 — CODE: main.tf lines 12-27

The resource group first, one line as always. Then the new resource, and its two decisions stand out. Allocation method Static: this address is reserved — it won't change when a future machine stops. And S K U Standard: the modern tier. The address itself is deliberately absent from the code. Azure will choose it.

## S007 — CODE: main.tf lines 29-32

One output, and it's the whole payoff: the address, read from I P underscore address. That value didn't exist at plan time — it's computed during creation, and the output is how you read it back the moment it exists.

## S008 — DIAGRAM: One resource, one address — chosen by Azure

The smallest diagram in the course, and every piece matters: the group anchors the address, the address is created with Static allocation and Standard S K U, and the output reads back the value Azure chose.

## S009 — TERMINAL: terraform apply

Apply time — two resources, and the output answers the question the code couldn't: an actual I P address. Azure picked it during creation, and Static now keeps it for this resource's lifetime. Computed value, exported the moment it exists — never guessed.

## S010 — CONCEPT: Common pitfall — Dynamic allocation for anything long-lived

- Dynamic releases the address on stop/deallocate — DNS and bookmarks break
- Static costs the same for a running resource — reserve by default
- Basic SKU is legacy; new work should use Standard
- A public IP alone isn't reachable — it needs a NIC/LB and rules (Lab 16)

Here are the pitfalls in this lab. One: dynamic allocation releases the address on stop or deallocate — d n s and bookmarks break. The address is held only while the resource runs; stop the machine, and Azure hands that i p to someone else. Every bookmark, d n s record, and firewall rule pointed at it now aims at a stranger. Two: static costs the same for a running resource — reserve by default. Static costs nothing extra while the resource runs, so make it your default. Three: the basic s k u is legacy — new work should use standard. Pick the standard s k u while you're at it. Four: a public i p alone isn't reachable — it needs a n i c or load balancer, and rules. Lab sixteen adds the rules.

## S011 — RECAP: recap

- azurerm_public_ip: a standalone, referenceable, billed resource
- Static reserves the address; Dynamic releases it on stop
- Standard SKU is the modern default
- ip_address is computed — exported via output
- Reachability still needs a NIC/LB and security rules

Quick recap — five things. One: azurerm public i p — a standalone, referenceable, billed resource. Two: static reserves the address; dynamic releases it on stop. Three: the standard s k u is the modern default. Four: the i p address is computed — exported via an output. Five: reachability still needs a n i c or load balancer, and security rules.

## S012 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S013 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/15-public-ip
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
