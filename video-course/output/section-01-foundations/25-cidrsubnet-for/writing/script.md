# Computed Subnets with cidrsubnet

**Episode:** section-01-foundations/25-cidrsubnet-for
**Lesson label:** Azure Foundations — Lab 25
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/25-cidrsubnet-for
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Computed Subnets with cidrsubnet

Twenty labs in, every subnet's address range was typed by hand. This lesson stops typing them. One base range, four tier names, and two functions — cidrsubnet and cidrhost — compute every subnet address and its first host automatically.

## S002 — CONCEPT: What you'll learn

- cidrsubnet(PREFIX, NEWBITS, NETNUM): carve a subnet from a base range
- New bits add to the prefix: /20 plus 6 new bits = /26
- NETNUM picks which slice — 0, 1, 2, 3
- A for-expression builds the whole subnet set from a name list

Here's what you'll learn. One: cidrsubnet — carve a subnet from a base range, using a prefix, new bits, and an index. Two: new bits add to the prefix — slash twenty plus six new bits gives slash twenty-six. Three: the index picks which slice — zero, one, two, three. Four: a for-expression that builds the whole subnet set from a name list.

## S003 — CONCEPT: Where this lab fits

- Lab 25 of the Foundations section
- Labs 09-11 taught types: list, map — this lab computes with them
- Every earlier subnet CIDR was hand-written; from here they're derived

This is lab twenty-five, and it closes a gap we've carried the whole section: every subnet so far had its address typed by hand — ten one forty dot one slash twenty-four, and friends. Hand-typed addresses don't scale and they invite typos. Today the addresses come from arithmetic.

## S004 — CONCEPT: Addresses as arithmetic, not text

- cidrsubnet extends the prefix: base /20 + 6 newbits = /26 slices
- NETNUM selects which slice: 0 → first, 1 → second, and so on
- cidrhost(CIDR, N) returns the Nth host inside a CIDR
- for-expressions turn a name list into full subnet definitions

The mental model: addresses as arithmetic. Cidrsubnet takes a prefix, a number of new bits, and an index. Six new bits on a slash twenty gives slash twenty-six — sixty-four addresses per slice — and the index picks which slice you get. Cidrhost then walks inside a slice: host one is the first usable address. Together they replace every hand-typed subnet address in this course so far.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 25-cidrsubnet-for
              ├── README.md
              └── main.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/25-cidrsubnet-for
```

The lab is in the course GitHub repository under Section 1, Foundations, link in the description. Readme and main dot t f — the entire lesson lives in the locals block.

## S006 — CODE: main.tf lines 25-41

The whole computation. Base: one seventy-two dot eighteen dot zero slash twenty. Tiers: web, app, data, mgmt. The for-expression walks the list with an index, and for each name computes the C I D R — cidrsubnet of the base, six new bits, index i — and the first host, cidrhost of that same subnet, host one. Four subnets, zero typed addresses.

## S007 — CODE: main.tf lines 43-55

The foundation: resource group, and the VNet whose address space is the base itself. Every subnet the loop produces will be carved out of exactly this range — the VNet is the canvas, cidrsubnet is the ruler.

## S008 — CODE: main.tf lines 57-69

The payoff. One subnet resource — with for each. The map is built from the computed list, keyed by name. Each instance takes its name from the key and its address from the value. Four real subnets from a single resource block — and the output prints the whole map: name, C I D R, first host.

## S009 — DIAGRAM: One base range, four computed slices

The arithmetic, drawn out: one base range, slash twenty. Cidrsubnet adds six bits — slash twenty-six — and the index picks the slice: web at dot zero, app at dot sixty-four, data at dot one twenty-eight, mgmt at dot one ninety-two. Four subnets, computed, not typed.

## S010 — TERMINAL: terraform apply

Apply time — six resources, and look at the subnet lines: one resource, four instances, each with its computed address. The output then shows the arithmetic paying off: web at dot zero slash twenty-six, app at dot sixty-four, data at dot one twenty-eight, mgmt at dot one ninety-two — and each slice's first host. Change the tier list, and the subnets recompute themselves.

## S011 — CONCEPT: Common pitfall — overlapping or undersized slices

- Newbits + base prefix must stay ≤ 32 — and leave room for Azure reserves
- NETNUM beyond the available slices is a plan-time error
- Azure reserves 5 addresses per subnet — a /26 really holds 59 usable
- Changing newbits or the index rewrites existing subnet addresses

Here are the pitfalls in this lab. One: new bits plus the base prefix must stay at most thirty two — and leave room for Azure's reserves. The math has to fit inside the address space, with slack for what Azure takes. Two: a netnum beyond the available slices is a plan-time error. The index can't point at a slice the base doesn't contain. Three: Azure reserves five addresses per subnet — a slash twenty six really holds fifty nine usable. Sixty-four addresses per slice, minus the five Azure keeps for itself. Four: changing new bits or the index rewrites existing subnet addresses. On live networks, that's a destructive change — check the size before you commit to it.

## S012 — RECAP: recap

- cidrsubnet(base, newbits, netnum) derives subnet addresses
- /20 + 6 newbits = /26 slices; the index selects the slice
- cidrhost(cidr, n) finds the Nth host — .1 is the first usable
- One subnet resource + for_each = N subnets from computed values
- Derived addresses scale; hand-typed addresses don't

Quick recap — five things. One: cidrsubnet derives subnet addresses from a base, new bits, and an index. Two: slash twenty plus six new bits gives slash twenty six slices — the index selects the slice. Three: cidrhost finds the nth host inside a slice — dot one is the first usable. Four: one subnet resource plus for each gives n subnets from computed values. Five: derived addresses scale — hand-typed addresses don't.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/25-cidrsubnet-for
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
