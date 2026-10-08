# templatefile and Cloud-Init

**Episode:** section-01-foundations/24-templatefile
**Lesson label:** Azure Foundations — Lab 24
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/24-templatefile
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: templatefile and Cloud-Init

A Linux machine that installs nginx on first boot — configured not in Terraform code, and not by hand, but from a template. This lesson introduces templatefile: render a file with variables, hand it to the VM, and let cloud-init do the rest.

## S002 — CONCEPT: What you'll learn

- templatefile(PATH, VARS): render a file with substituted values
- cloud-init: the first-boot bootstrap script for Linux VMs
- custom_data on azurerm_linux_virtual_machine — must be base64-encoded
- SSH key auth instead of passwords for the Linux VM

Here's what you'll learn. One: templatefile — render a file with substituted values. Two: cloud-init — the first-boot bootstrap script for Linux V Ms. Three: custom data on azurerm linux virtual machine — which must be base sixty-four encoded. Four: S S H key authentication instead of passwords for the Linux V M.

## S003 — CONCEPT: Where this lab fits

- Lab 24 of the Foundations section
- Labs 17 and 21 built Windows VMs — passwords and data disks
- Linux VMs bootstrap differently: cloud-init, not a script you paste

This is lab twenty-four, and it switches the operating system. Windows machines — like the ones in earlier labs — are configured after login. Linux machines can bootstrap themselves on first boot, and today we write that bootstrap as a template file instead of burying a script inside the configuration.

## S004 — CONCEPT: Templates keep scripts out of the configuration

- cloud-init.tpl is a plain file with ${ } and %{ for %} directives
- templatefile(PATH, VARS) substitutes them at plan time
- custom_data must be base64-encoded — the VM decodes it on boot
- Change the template → Terraform updates custom_data → VM re-runs it

The mental model: the template is a separate file, and the configuration stays about infrastructure. Templatefile takes the path and a map of values, and produces the finished text. The template speaks two languages: dollar-brace for single values, and percent-brace blocks for loops. Keep big scripts out of dot t f files — cleaner to read, easier to reuse.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 24-templatefile
              ├── README.md
              ├── main.tf
              ├── variables.tf
              ├── cloud-init.tpl
              └── terraform.tfvars.example

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/24-templatefile
```

The lab is in the course GitHub repository under Section 1, Foundations, link in the description. Note the new file: cloud-init dot t p l — the template that gets rendered.

## S006 — CODE: cloud-init.tpl lines 4-16

The template itself — and it's not Terraform. Cloud-config format, read by cloud-init on first boot. Hostname comes from a variable, package update, and a loop over the packages list — nginx and curl. Then two commands: enable nginx, and write a homepage that proves the bootstrap ran.

## S007 — CODE: main.tf lines 32-45

Where the template becomes real. Templatefile takes the path and a map — hostname web dash templatefile, packages nginx and curl — and returns the finished text. It runs at plan time: the rendered result is part of the configuration from that moment on, stored inside the local named rendered.

## S008 — CODE: main.tf lines 81-105

The Linux machine. Custom data must be base64-encoded — so the rendered text goes through base64encode before the VM receives it. Authentication is an S S H key from a sensitive variable — no password anywhere. On first boot, cloud-init decodes the data and runs it: nginx installs itself.

## S009 — DIAGRAM: From template to first boot

The pipeline, drawn out: the template file and the values map feed templatefile, which produces the finished script. Base64-encode it, and it lands in the machine's custom data — executed by cloud-init, once, on first boot. The configuration never contains the script; it contains the recipe for producing it.

## S010 — TERMINAL: terraform apply

Apply time — five resources, and the machine takes about two minutes. The output command then prints the preview: the rendered template, with the hostname substituted and the package loop expanded. That preview is how you check the substitution without decoding base64 by hand.

## S011 — CONCEPT: Common pitfall — raw template markers in comments

- %{ and ${ } inside a comment are still parsed as directives
- A stray ${ in the template breaks rendering at plan time
- custom_data only runs cloud-init on FIRST boot — changes need care
- Use %{ ~ to trim whitespace when a loop must not leave blank lines

Here are the pitfalls in this lab. One: percent brace and dollar brace inside a comment are still parsed as directives. In a Terraform file, hash means comment; in a template, hash is just text — and any directive inside it stays live. Two: a stray dollar brace in the template breaks rendering at plan time. Any accidental interpolation fails the whole template — that's why the lab's template spells its markers out in words. Three: custom data runs cloud-init on first boot only — changes need care. Editing the template later doesn't re-run the script on an existing machine. Four: use the percent brace tilde form to trim whitespace, so a loop doesn't leave blank lines. Keep template files free of stray interpolation, even in comments.

## S012 — RECAP: recap

- templatefile(PATH, VARS): substitute ${ } values and %{ for %} loops
- cloud-init.tpl stays a separate file — configuration stays clean
- custom_data must be base64encode(...) — the VM decodes on first boot
- SSH key auth via admin_ssh_key — no passwords on Linux VMs
- terraform output rendered_preview shows the substitution worked

Quick recap — five things. One: templatefile takes a path and a vars map — substituting dollar brace values and percent brace loops. Two: the cloud-init t p l stays a separate file — configuration stays clean. Three: custom data must be base sixty four encoded — the v m decodes it on first boot. Four: s s h key auth via the admin s s h key resource — no passwords on linux v m s. Five: the rendered preview output shows the substitution worked.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/24-templatefile
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
