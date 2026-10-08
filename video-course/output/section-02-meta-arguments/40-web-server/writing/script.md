# Script — Lab 40: A Server Without SSH: cloud-init + custom_data

*Terraform Meta-arguments — Lab 40. Generated from `source/terraform-inventory.json` + `source/source-manifest.json` (ACTIVE_LAB = `section-02-meta-arguments/40-web-server`).*

---

## S001 — TITLE: A Server Without SSH: cloud-init + custom_data

**A Server Without SSH: cloud-init + custom_data**

Welcome back. This is Lab 40, and it builds something you can actually open in a browser: a web server. No provisioner, no SSH session from Terraform — instead, cloud-init runs at first boot and installs nginx. A heredoc holds the script, base64encode feeds it to the VM, and a public IP plus an NSG rule make it reachable. Let's build it.

---

## S002 — CONCEPT: What you'll learn

- A heredoc (<<-EOT) holds cloud-init YAML in locals
- custom_data = base64encode(...) — script delivery at first boot
- Public IP inside ip_configuration + an NSG rule for HTTP

**What you'll learn**

Three things in this lesson. One: the heredoc — a multi-line string written right into locals, holding cloud-init YAML. Two: custom data — the VM argument that carries the script, which must be base64-encoded, and which runs once at first boot. Three: the network path — a public IP attached inside the NIC's ip configuration, and an NSG rule opening port 80.

---

## S003 — CONCEPT: Where this lab fits

- Labs 35–37: VMs with private IPs only
- This lab: first internet-reachable VM — and first cloud-init
- Provisioners come later (lab 45) — cloud-init first, on purpose

**Where this lab fits**

Placement. Every VM so far — labs 35 through 37 — had a private IP and no way in. This lab builds the first internet-reachable server: public IP on the NIC, HTTP open. And it deliberately uses cloud-init BEFORE the course shows provisioners, in lab 45: cloud-init is the Terraform-native way to configure a VM at first boot — idempotent, no SSH dependency, and it belongs in your toolbox first.

---

## S004 — CONCEPT: Where to find this lab

**Where to find this lab**

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-02-meta-arguments
          └── 40-web-server

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-02-meta-arguments/40-web-server
```

You'll find this lab in the course GitHub repository under Section 2, Meta-arguments — the lab named 40-web-server. The direct link is in the video description. Main dot T F holds everything; terraform dot T F pins the providers.

---

## S005 — CODE

Terraform dot T F pins the tooling: Terraform 1.5 or newer, and the azurerm provider around version 3.70 — no extra providers this time. The provider block at the bottom bridges to Azure; the empty features block enables the provider's defaults. Every interesting line lives in main dot T F.

---

## S006 — CODE

**Steps:**

1. The familiar sensitive SSH key variable — required, no default. Even a server you'll reach by browser still needs key-based admin access.
   - active: [10, 11, 12, 13]

The familiar sensitive SSH key variable — required, no default. Even a server you'll reach by browser still needs key-based admin access.

---

## S007 — CODE

**Steps:**

1. The star of the setup: a heredoc. cloud init equals, then <<-EOT, the YAML lines, and EOT to close. The double dash in EOT means indentation is stripped — the YAML can sit neatly indented inside the locals block and still arrive clean.
   - active: [16, 17]
2. The content is cloud-init YAML — it must start with the hash cloud-config marker. First directive: package update true, then packages: nginx. Cloud-init installs the web server before anything else runs.
   - active: [18, 19, 20, 21]
3. Then runcmd — commands to run after boot: enable and start nginx, and write the homepage — an h1 line into var www html index dot html. That echo is the page you'll see in the browser later.
   - active: [22, 23, 24, 25]

The star of the setup: a heredoc. cloud init equals, then <<-EOT, the YAML lines, and EOT to close. The double dash in EOT means indentation is stripped — the YAML can sit neatly indented inside the locals block and still arrive clean. The content is cloud-init YAML — it must start with the hash cloud-config marker. First directive: package update true, then packages: nginx. Cloud-init installs the web server before anything else runs. Then runcmd — commands to run after boot: enable and start nginx, and write the homepage — an h1 line into var www html index dot html. That echo is the page you'll see in the browser later.

---

## S008 — CODE

**Steps:**

1. The network base: resource group rg dash webserver, VNet on 10.220 slash 16, subnet snet web. Standard shape — the differences come next.
   - active: [39, 44, 47]

The network base: resource group rg dash webserver, VNet on 10.220 slash 16, subnet snet web. Standard shape — the differences come next.

---

## S009 — CODE

**Steps:**

1. The NSG with one rule: allow HTTP. Name allow dash HTTP, priority 200, inbound, allow, TCP — and the destination port range 80. Nothing exotic — the classic web-server opening.
   - active: [55, 56, 57, 58, 59, 60, 61, 62]
2. But notice the README's honest note: this NSG is created and left UNASSOCIATED — no subnet or NIC references it in this lab. With no NSG attached, Azure applies no filtering at all, so the site works; attaching the NSG — making the rule load-bearing — is a later lab's job. This one is scaffolding you'll wire up soon.
   - active: [51, 52]

The NSG with one rule: allow HTTP. Name allow dash HTTP, priority 200, inbound, allow, TCP — and the destination port range 80. Nothing exotic — the classic web-server opening. But notice the README's honest note: this NSG is created and left UNASSOCIATED — no subnet or NIC references it in this lab. With no NSG attached, Azure applies no filtering at all, so the site works; attaching the NSG — making the rule load-bearing — is a later lab's job. This one is scaffolding you'll wire up soon.

---

## S010 — CODE

**Steps:**

1. The public IP: static allocation on the standard SKU, so the address survives restarts and redeploys. Named pip dash webserver.
   - active: [70, 71, 74, 75]
2. And the NIC's ip configuration is where it attaches — public ip address id equals azurerm public ip dot web dot id. A public IP never attaches to a VM directly; it rides on the NIC's ip configuration. That's the line people forget.
   - active: [83, 84, 85, 86, 87, 88]

The public IP: static allocation on the standard SKU, so the address survives restarts and redeploys. Named pip dash webserver. And the NIC's ip configuration is where it attaches — public ip address id equals azurerm public ip dot web dot id. A public IP never attaches to a VM directly; it rides on the NIC's ip configuration. That's the line people forget.

---

## S011 — CODE

**Steps:**

1. The VM block — the lab-35 anatomy again: SSH key, os disk, source image. One line is new, and it's the point of the lab: custom data equals base64encode of local dot cloud init.
   - active: [92, 99]
2. custom data MUST be base64-encoded — Azure takes the encoded blob and decodes it at first boot, feeding it to cloud-init. And once: custom data runs on FIRST boot only. Re-apply with an edited script and an existing VM does nothing new — changing custom data forces a replacement.
   - active: [92, 99]
3. The final line outputs the public IP — unknown until apply completes. Open http slash slash that IP, and nginx's page — written by cloud-init — is waiting.
   - active: [118]

The VM block — the lab-35 anatomy again: SSH key, os disk, source image. One line is new, and it's the point of the lab: custom data equals base64encode of local dot cloud init. custom data MUST be base64-encoded — Azure takes the encoded blob and decodes it at first boot, feeding it to cloud-init. And once: custom data runs on FIRST boot only. Re-apply with an edited script and an existing VM does nothing new — changing custom data forces a replacement. The final line outputs the public IP — unknown until apply completes. Open http slash slash that IP, and nginx's page — written by cloud-init — is waiting.

---

## S012 — DIAGRAM: How the pieces connect

**How the pieces connect**

**Steps:**

1. Here's how the pieces connect.
2. The inputs: sensitive SSH key, and the cloud-init heredoc in locals.
   - active: ['locals']
3. The resource group groups everything in Azure.
   - active: ['rg']
4. The VNet and subnet at 10.220.1.0 slash 24.
   - active: ['vnet']
5. The NSG with the Allow-HTTP rule — created but unassociated in this lab.
   - active: ['nsg']
6. The public IP — static, standard — attaches inside the NIC's ip configuration.
   - active: ['pip', 'nic']
7. The VM: NIC attached, and custom_data = base64encode of the heredoc — nginx installs at first boot.
   - active: ['vm']
8. Everything lands inside your Azure subscription.

Here's how the pieces connect. The inputs: sensitive SSH key, and the cloud-init heredoc in locals. The resource group groups everything in Azure. The VNet and subnet at 10.220.1.0 slash 24. The NSG with the Allow-HTTP rule — created but unassociated in this lab. The public IP — static, standard — attaches inside the NIC's ip configuration. The VM: NIC attached, and custom_data = base64encode of the heredoc — nginx installs at first boot. Everything lands inside your Azure subscription.

---

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Resource group, VNet, subnet, NSG, public IP, NIC, and the VM — seven to add, zero to destroy. The VM shows the sensitive SSH key redacted; the cloud-init script rides inside custom data, encoded.

---

## S014 — TERMINAL

And after apply — terraform output public ip, an illustrative view. Azure assigned the address at apply time; the splat-free single value comes straight from the public IP resource. Point a browser at it and the cloud-init page loads.

---

## S015 — CONCEPT: Common pitfall

- custom_data runs ONCE at first boot — edits force a VM replacement
- custom_data must be base64encode()d — raw YAML is rejected
- The NSG is unassociated here — no filtering until it's attached

**Common pitfall**

Three pitfalls. One: custom data runs once, at first boot. Edit the heredoc and re-apply, and Terraform doesn't rerun anything — it flags the VM for replacement, because custom data changed. Treat the script as part of the machine's identity. Two: the base64 encoding is mandatory — pass raw YAML and Azure rejects or ignores it; the encode call is not optional styling. Three: the unassociated NSG — it exists, its rule says allow HTTP, but nothing references it, so no filtering happens at all. When a later lab attaches it, the rule becomes load-bearing — expect traffic behavior to change the moment it's wired up.

---

## S016 — RECAP

- <<-EOT heredoc — multi-line cloud-init YAML inside locals
- custom_data = base64encode(local.cloud_init) — mandatory encoding
- cloud-init runs once at first boot — package_update + nginx + runcmd
- public_ip_address_id lives in the NIC's ip_configuration
- The NSG Allow-HTTP rule is created but unassociated (later lab)

Quick recap — five things. One: the heredoc holds multi-line cloud-init YAML right in locals, indentation stripped by the double-dash EOT. Two: custom data takes base64encode of that heredoc — the encoding is mandatory. Three: cloud-init runs at first boot — updates packages, installs nginx, writes the homepage. Four: the public IP attaches inside the NIC's ip configuration — never to the VM directly. Five: the NSG rule exists but is deliberately unassociated in this lab. No SSH, no provisioner — a server configured by its own first boot.

---

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

---

## S018 — CONCEPT: Thanks for watching

**Thanks for watching**

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-02-meta-arguments/40-web-server
```

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.

---
