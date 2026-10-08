# The Virtual Machine

**Episode:** section-01-foundations/17-virtual-machine
**Lesson label:** Azure Foundations — Lab 17
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/17-virtual-machine
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: The Virtual Machine

Six lessons of parts, and today the machine: this lab wires everything from the last six lessons — network, subnet, security group, public I P, N I C — into one dependency chain that ends in a running Windows virtual machine.

## S002 — CONCEPT: What you'll learn

- The full VM stack: one configuration, seven resources
- How references build the dependency chain automatically
- A sensitive variable for the admin password — never hard-coded
- os_disk and source_image_reference: choosing the machine's disk and image

Here's what you'll learn. One: the full V M stack — one configuration, seven resources. Two: how references build the dependency chain automatically. Three: a sensitive variable for the admin password — never hard-coded. Four: the O S disk and source image reference — choosing the machine's disk and image.

## S003 — CONCEPT: Where this lab fits

- Lab 17 of the Foundations section
- Every piece was taught in Labs 12–16 — today they become one chain
- Terraform derives the build order from references — no depends_on needed

This is lab seventeen, and nothing in it is new. Network, subnet, security group, public I P, network interface — every piece was taught over the last five lessons. What's new is the wiring: one configuration that builds all of it, in the right order, without a single explicit depends on. That's what references do.

## S004 — CONCEPT: The chain Terraform builds for you

- NIC references subnet + public IP — they must exist first
- VM references the NIC — it comes last, automatically
- References, not names: attributes like azurerm_subnet.web.id carry the order
- No depends_on anywhere — the graph is derived from the references

Here's the payoff of five lessons of reference discipline. Terraform reads the attributes you reference — the N I C pointing at a subnet I D, the V M pointing at the N I C — and builds the whole dependency graph on its own. That's why nothing in this file says depends on: the order is derived, guaranteed, and updated automatically when you change the wiring. Explicit references aren't just style. They are the build plan.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 17-virtual-machine
              ├── README.md
              ├── main.tf
              ├── terraform.tf
              ├── variables.tf
              └── terraform.tfvars.example

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/17-virtual-machine
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Readme, main dot t f, terraform dot t f, and a terraform dot t f vars example for the password.

## S006 — CODE: main.tf lines 10-28

Two variables open the file. Admin username, with a default. And admin password — sensitive equals true, no default. That flag means Terraform masks the value in every plan and apply log. If the t f vars file doesn't supply it, Terraform asks at the prompt. It is never written into the code.

## S007 — CODE: main.tf lines 30-50

The network stack, familiar from the last four lessons: resource group, VNet on ten one twenty slash sixteen, and the web subnet. Same standalone form, same references. Deliberately boring — because the wiring that matters is ahead.

## S008 — CODE: main.tf lines 79-90

The network interface, and one line is new. The I P configuration still binds to the subnet — but now it also carries public I P address I D, referencing the public I P created just above. One NIC, two connections: private access through the subnet, inbound access through the public address.

## S009 — CODE: main.tf lines 92-116

And the machine itself. Network interface I Ds binds the V M to the N I C — the reference that puts it last in the build order. Size: Standard B one s, a small, cheap machine. The admin credentials flow from the variables — the password arrives masked. Then two nested blocks: the O S disk, and the source image reference, whose four fields together pin the exact marketplace image.

## S010 — DIAGRAM: Six resources, one chain — built from references

The whole stack drawn out. Variables feed the machine, the network chain runs from group to subnet to N I C, the public I P joins at the N I C, and the V M is last — all of it ordered by references alone.

## S011 — TERMINAL: terraform apply

Apply time — seven resources, and watch the order in the log: network first, machine last, taking nearly three minutes as the image installs. The output hands back the public I P — the address you'd R D P to, exactly the port the security rule opened. One configuration built all of it, in the right order, because every reference said so.

## S012 — CONCEPT: Common pitfall — putting secrets in the configuration

- The password exists only as a sensitive variable — never a hard-coded string
- sensitive masks the value in plan/apply logs (state-file caveat: Lab 20)
- Source image references must match the marketplace exactly — four fields
- A VM without its NIC reference is unbuildable — references define the chain

Here are the pitfalls in this lab. One: the password exists only as a sensitive variable — never a hard-coded string. Hard-code it instead, and it's in your repository forever — git history doesn't forget. Two: sensitive masks the value in plan and apply logs — the state-file caveat comes in lab twenty. The mask keeps the password out of every log line. Three: source image references must match the marketplace exactly — four fields. Get one wrong and the plan fails before anything is built. Four: a v m without its n i c reference is unbuildable — references define the chain. Secrets come from variables; images from exact references; the build order from references.

## S013 — RECAP: recap

- One configuration, seven resources — every lab 12–16 piece, wired
- Terraform derives the whole build order from references — no depends_on
- NIC: subnet for private traffic + public IP for inbound
- Windows VM: size, os_disk, and a four-field source_image_reference
- The admin password is a sensitive input — never in the code

Quick recap — five things. One: one configuration, seven resources — every piece from labs twelve to sixteen, wired together. Two: Terraform derives the whole build order from references — no depends on anywhere. Three: the n i c gives the subnet for private traffic, and the public i p for inbound. Four: the windows v m needs a size, an o s disk, and a four-field source image reference. Five: the admin password is a sensitive input — never in the code.

## S014 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S015 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/17-virtual-machine
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
