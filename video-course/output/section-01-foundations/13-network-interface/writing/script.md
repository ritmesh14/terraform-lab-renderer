# The Network Interface

**Episode:** section-01-foundations/13-network-interface
**Lesson label:** Azure Foundations — Lab 13
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/13-network-interface
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: The Network Interface

The last two lessons built networks — but nothing lives in them yet. This lesson adds the bridge between a network and a machine: the network interface, the N I C, the resource that will bind a virtual machine to its subnet in the coming V M labs.

## S002 — CONCEPT: What you'll learn

- azurerm_network_interface: a VM's network card in Azure
- ip_configuration binds the NIC to a subnet by id
- Dynamic private IP: Azure picks a free address from the subnet
- Outputs: the NIC's id, and the private IP Azure chose

Here's what you'll learn. One: azurerm network interface — a V M's network card in Azure. Two: the I P configuration block — binding the N I C to a subnet by I D. Three: dynamic private I P — Azure picks a free address from the subnet. Four: outputs — the N I C's I D, and the private I P Azure chose.

## S003 — CONCEPT: Where this lab fits

- Lab 13 of the Foundations section
- Lab 12 ended with an output: the web subnet's id — a NIC consumes exactly that
- The NIC is the bridge from network labs to the VM lab (Lab 17)

This is lab thirteen, and it closes a loop. Last lesson ended with an output — a subnet I D waiting for a consumer. Here it is: the network interface, which takes that subnet I D and gives a future machine its place in the network.

## S004 — CONCEPT: What a NIC actually is

- An Azure VM never touches a subnet directly — it attaches through a NIC
- A NIC lives in exactly one subnet, via its ip_configuration
- subnet_id = a reference, not a copy — same dependency wiring as always
- Dynamic allocation: the private IP is computed, Azure's choice

A quick mental model. An Azure virtual machine never holds an address in a subnet directly — it's attached through a network interface. The N I C is the machine's network card: it lives in one subnet, carries at least one I P configuration, and holds the addresses. And the wiring should look familiar: subnet I D is a reference to last lab's resource, so Terraform orders the build automatically. Same dependency rule as every lesson.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 13-network-interface
              ├── README.md
              ├── main.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/13-network-interface
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Readme, main dot t f, and terraform dot t f — one file of resources, one of plumbing.

## S006 — CODE: main.tf lines 14-34

The network home first, and it's familiar on purpose: resource group, VNet with a ten ninety slash sixteen space, and the web subnet on ten ninety dot one dot zero slash twenty four — the standalone form from last lesson, kept identical so the new resource stands out.

## S007 — CODE: main.tf lines 36-49

Here's the new resource: azurerm network interface. A name and a group, then one I P configuration block. Two fields do the work. Subnet I D references the subnet we just built — Terraform will create it first. And private I P address allocation says Dynamic: Azure picks any free address in the subnet's range. We don't choose it. We observe it.

## S008 — CODE: main.tf lines 51-55

Two outputs report the result. The N I C's I D — the handle a V M will attach to later — and the private I P, which is only known after creation, because Azure chose it. Computed values are exactly what outputs are for.

## S009 — DIAGRAM: The NIC binds a future VM to its subnet

The chain drawn out: VNet, subnet, then the N I C with its I P configuration. The subnet I D reference creates the order, and the dynamic private I P is Azure's pick from the subnet's range.

## S010 — TERMINAL: terraform apply

Apply time — four resources. The output answers the question the code couldn't: the private I P came back as an address in the subnet's range — Azure's pick, not ours. And the N I C's I D is exported, the handle the V M lab will reference when a machine finally appears.

## S011 — CONCEPT: Common pitfall — expecting to pick the private IP

- Dynamic allocation: the address is Azure's choice — read it, don't set it
- It exists only after creation — capture it in an output
- A NIC without a VM is valid: it's a real, standalone resource
- Each ip_configuration binds the NIC to one subnet

Here are the pitfalls in this lab. One: dynamic allocation means the address is Azure's choice — read it, don't set it. Azure hands out a free address from the subnet's range; today it picked the first available one. Two: it exists only after creation — capture it in an output. You can't know the address before apply, so the output is how you read it back. Three: a n i c without a v m is valid — it's a real, standalone resource. It can be created, addressed, and referenced on its own. Four: each i p configuration binds the n i c to one subnet. That reference is what places the n i c in your network — and the dependency comes for free. If you ever need a fixed address, that's a different allocation mode, and it belongs to a later lesson.

## S012 — RECAP: recap

- A NIC is a VM's network card — and it lives in a subnet
- ip_configuration.subnet_id references the subnet resource
- Dynamic private IP: computed by Azure, exported via output
- nic.id is the handle the VM (Lab 17) will attach to
- Same dependency wiring: references, never depends_on

Quick recap — five things. One: a n i c is a v m's network card — and it lives in a subnet. Two: the i p configuration's subnet i d references the subnet resource. Three: the dynamic private i p is computed by Azure and exported via an output. Four: the n i c's i d is the handle lab seventeen's v m will attach to. Five: same dependency wiring — references, never depends on.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/13-network-interface
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
