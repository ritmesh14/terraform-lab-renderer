# Network Security Groups

**Episode:** section-01-foundations/16-network-security-group
**Lesson label:** Azure Foundations — Lab 16
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/16-network-security-group
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Network Security Groups

Last lesson built a door to the internet — a public I P. But a door with no rules lets anyone through. This lesson builds the doorman: the network security group, a stateful firewall with prioritized rules, attached to a subnet by its own association resource.

## S002 — CONCEPT: What you'll learn

- azurerm_network_security_group: a stateful firewall for subnets and NICs
- security_rule blocks: priority, direction, access, ports
- Lower priority number is evaluated first — 200 before 300
- Subnet ↔ NSG via its own association resource

Here's what you'll learn. One: azurerm network security group — a stateful firewall for subnets and N I Cs. Two: security rule blocks — priority, direction, access, and ports. Three: a lower priority number is evaluated first — two hundred before three hundred. Four: connecting the group to a subnet through its own association resource.

## S003 — CONCEPT: Where this lab fits

- Lab 16 of the Foundations section
- Lab 15 created a public IP — reachable means filtered
- Lab 17's VM will log in over the RDP rule built today

This is lab sixteen, and it answers the question lab fifteen left open: an I P address exists — but who's allowed to knock? The security group answers that. And it sets up the very next lab, where a Windows virtual machine finally uses the R D P rule we're about to write.

## S004 — CONCEPT: A stateful firewall with an ordering rule

- Default inbound: deny — you open only the ports you need
- Rules evaluated by priority, lowest number first
- Stateful: reply traffic to an allowed flow is permitted automatically
- Attach by association resource — at subnet or NIC level

The mental model: a stateful firewall with a strict ordering rule. By default, inbound traffic is denied — you open exactly the ports you need, nothing more. Rules are evaluated in priority order, lowest number first, so a two hundred is decided before a three hundred. Stateful means replies to an allowed connection flow back automatically. And attaching the group to a subnet is its own resource — an association — which is where today's configuration ends.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 16-network-security-group
              ├── README.md
              ├── main.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/16-network-security-group
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Readme, main dot t f, terraform dot t f — and most of main dot t f is rules.

## S006 — CODE: main.tf lines 18-32

The backdrop first: group, VNet on ten one ten slash sixteen, and the web subnet — the standalone form from lab twelve, unchanged. The security group will attach to exactly this subnet, so its rules protect everything that ever joins it.

## S007 — CODE: main.tf lines 34-52

The security group, and its first rule. Eight fields, but three decide everything: direction Inbound, access Allow, and destination port three three eight nine — R D P. Priority two hundred: this rule is evaluated before anything numbered higher. The asterisks mean any source I P and any source port — deliberately loose, because this is a lab. Tighten the source in production.

## S008 — CODE: main.tf lines 54-71

A second rule — H T T P S on port four forty three, priority three hundred — evaluated only if the two hundred rule didn't already decide. And then the piece that's easy to forget: the association resource. Creating the group does nothing by itself. This block binds it to the subnet — that's when the rules take effect.

## S009 — DIAGRAM: Rules by priority, attached by association

The doorman, drawn out: inbound traffic meets the security group, whose two allow rules are checked in priority order — two hundred first, then three hundred. And the association is what arms it, binding group to subnet. Everything else stays denied.

## S010 — TERMINAL: terraform apply

Apply time — five resources, and the last line matters most: the association. Group and subnet each existed as resources, but only this block connects them. From that moment, inbound traffic to that subnet is filtered by exactly the rules we wrote, in exactly the priority order we set.

## S011 — CONCEPT: Common pitfall — ignoring rule priority

- Lowest priority number is evaluated first — a broad 200 can mask a 300
- A wide Allow at 200 makes a narrower later rule unreachable
- source_address_prefix "*" = the entire internet — tighten in production
- Subnet-level and NIC-level NSGs can both apply — don't double-manage

Here are the pitfalls in this lab. One: the lowest priority number is evaluated first — a broad rule at two hundred can mask a rule at three hundred. Rule order is the whole design of an n s g. Two: a wide allow at two hundred makes a narrower later rule unreachable. Traffic matching the broad rule never gets that far down the list. Three: a wildcard source prefix means the entire internet — tighten in production. That asterisk is honest for a demo and dangerous for anything real. Four: subnet-level and n i c-level n s g s can both apply — don't double-manage. Two layers of rules are easy to contradict; the rule of thumb is most specific allow first, and everything else stays denied.

## S012 — RECAP: recap

- NSG: stateful firewall, default inbound deny
- security_rule blocks with priority — lowest number wins
- Attach via azurerm_subnet_network_security_group_association
- Open only what you need: 3389 (RDP) and 443 (HTTPS) here
- Wildcard source prefixes are demo-grade — tighten for production

Quick recap — five things. One: an n s g is a stateful firewall — default inbound deny. Two: security rule blocks carry priorities — the lowest number wins. Three: attach with the subnet network security group association resource. Four: open only what you need — three three eight nine for r d p, and four four three for h t t p s. Five: wildcard source prefixes are demo-grade — tighten for production.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/16-network-security-group
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
