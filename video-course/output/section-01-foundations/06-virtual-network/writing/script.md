# Your First Virtual Network

**Episode:** section-01-foundations/06-virtual-network
**Lesson label:** Azure Foundations — Lab 06
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/06-virtual-network
**Scope:** `main.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Your First Virtual Network

Everything we've built so far lives alone in its resource group. Today we start connecting things, with your first virtual network: private I P space in Azure, with subnets carved out for the workloads to come.

## S002 — CONCEPT: What you'll learn

- What a VNet is: your private IP space inside Azure
- Reading a CIDR block: what 10.20.0.0/16 actually means
- Inline subnet blocks — the quick way to add subnets
- Why subnets matter for everything that follows

Here's what you'll learn. One: what a VNet is — your private I P space inside Azure. Two: reading a C I D R block — what ten twenty dot zero slash sixteen actually means. Three: inline subnet blocks — the quick way to add subnets. Four: why subnets matter for everything that follows.

## S003 — CONCEPT: Where this lab fits

- Lab 6 of the Foundations section
- First networking lab — the base for VMs and app workloads
- Reference chain from Lab 4 reused: locals feed resources

This is lab six, and it's the first networking lab of the course. From here on, most resources will live inside a network. Virtual machines, databases, app environments, they all need subnets to sit in. The code itself is small, but it's the foundation everything later stands on.

## S004 — CONCEPT: Reading a CIDR block in 60 seconds

- 10.20.0.0/16 — network 10.20.x.x, 65,536 addresses
- The /16 = how many bits are fixed; the rest is yours to slice
- A /24 subnet fixes one more byte: 10.20.1.0/24 = 256 addresses
- Subnets must fit inside the VNet's space and not overlap

Sixty seconds on C I D R, because it's the only networking math this course needs. Ten twenty dot zero dot zero slash sixteen means: the first sixteen bits, the first two numbers, are the network. Everything after is yours. That's about sixty five thousand addresses. A slash twenty four subnet fixes one more number, so ten twenty dot one dot zero slash twenty four is a piece of that space, two hundred fifty six addresses big. The only rule to remember: subnets must fit inside the network, and they must not overlap.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 06-virtual-network
              ├── README.md
              └── main.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/06-virtual-network
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, link in the description. One file: main dot T F, with a resource group, a virtual network, and two subnets.

## S006 — CODE: main.tf lines 25-36

Locals first: the resource group name, the region, and the network's name. Then the resource group itself, referencing those locals. This is the same opening pattern as every lab since four: names live in one place, resources reference them.

## S007 — CODE: main.tf lines 38-44

Now the new resource: a virtual network. Its name comes from locals, and its location and resource group come from the group we just defined, the reference chain you already know. The new part is address space. It's a list, because a V N E T can hold several ranges, and here we give it one: ten twenty dot zero dot zero slash sixteen. That's this network's private territory inside Azure.

## S008 — DIAGRAM: One VNet, two subnets — how the space is sliced

Here's the space as a picture. The big box is the V N E T, sixty five thousand addresses wide. Inside it, two subnets: the web subnet at ten twenty dot one dot zero, and the app subnet at ten twenty dot two dot zero, each a slash twenty four slice. Resources in the web subnet can talk to the app subnet, because they share this private space. And nothing here is reachable from the public internet unless we deliberately expose it later.

## S009 — CODE: main.tf lines 46-56

The subnets are defined inside the V N E T block itself, one small block per subnet: a name and an address prefix. This inline style is the quick way, and for a small network it's perfectly fine. The trade-off, as the comment notes, is flexibility. Each inline subnet is welded to this V N E T resource. When you need subnets with their own lifecycles, route tables, or network security groups, you define them as separate resources, which is a later lab's topic.

## S010 — CODE: main.tf lines 59-62

Two outputs finish the file: the V N E T's I D and its name. The I D is the one to watch. Later labs and other resources reference a network by its I D, so printing it here is both a sanity check and a preview of the reference chains to come.

## S011 — TERMINAL

Apply time. The resource group first, then the virtual network with both subnets inside it. Notice the plan shows the subnets as part of the V N E T, not as separate resources, because that's how we declared them: inline.

## S012 — CONCEPT: Common pitfall — overlapping address space

- Two subnets claiming 10.20.1.0/24 → Azure rejects the VNet
- A subnet must sit inside the VNet's address_space
- Plan your ranges before you write them: 10.20.1.x web, 10.20.2.x app
- Peered VNets must not overlap either — ranges are forever-ish

Here are the pitfalls in this lab. One: two subnets claiming the same range — ten twenty dot one dot zero slash twenty four — and Azure rejects the v net. Overlapping prefixes are the classic networking mistake, and Azure catches them at apply time. Two: a subnet must sit inside the v net's address space. Anything outside it fails the whole apply. Three: plan your ranges before you write them — ten twenty dot one for web, ten twenty dot two for app. A minute of planning beats renumbering later. Four: peered networks must not overlap either — address ranges are effectively forever. Renumbering a used network is a project of its own, so spend that minute planning before you write ranges down.

## S013 — RECAP

- A VNet is your private IP space inside Azure
- address_space is a LIST of CIDR blocks — here one /16
- A /24 subnet is a 256-address slice of that space
- Inline subnet {} blocks are quick but welded to the VNet resource
- Later labs reference the VNet by its id output

Quick recap — five things. One: a v net is your private i p space inside Azure. Two: address space is a list of c i d r blocks — here one slash sixteen. Three: a slash twenty four subnet is a two hundred fifty six address slice of that space. Four: inline subnet blocks are quick, but welded to the v net resource. Five: later labs reference the v net by its i d output.

## S014 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S015 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/06-virtual-network
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
