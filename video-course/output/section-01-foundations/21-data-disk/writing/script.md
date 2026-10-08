# Data Disks and Attachments

**Episode:** section-01-foundations/21-data-disk
**Lesson label:** Azure Foundations — Lab 21
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/21-data-disk
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Data Disks and Attachments

Every virtual machine so far carried exactly one disk — the one Windows was installed on. Real applications need more: a separate disk for databases, files, backups. This lesson builds that second disk, and the dedicated resource that bolts it onto the machine.

## S002 — CONCEPT: What you'll learn

- azurerm_managed_disk: a standalone managed disk you create directly
- azurerm_virtual_machine_data_disk_attachment: the LUN-level link
- OS disk vs data disk — Windows lives on one, your data on the other
- LUN 0-63: how the guest OS identifies each attached disk

Here's what you'll learn. One: azurerm managed disk — a standalone managed disk you create directly. Two: the data disk attachment — the L U N-level link between disk and machine. Three: O S disk versus data disk — Windows lives on one, your data on the other. Four: L U N zero through sixty-three — how the guest O S identifies each attached disk.

## S003 — CONCEPT: Where this lab fits

- Lab 21 of the Foundations section
- Labs 17 and 20 built Windows VMs — each had only its OS disk
- The attachment pattern returns in stateful app deployments

This is lab twenty-one. Every machine we've built so far boots, and that's all it can do — stop it, and its data is gone. Today we give the machine a second, persistent disk. When we later deploy real applications, this disk is where their state will live.

## S004 — CONCEPT: One disk for the system, one for the data

- The OS disk is created automatically with the VM — it holds Windows
- A data disk is independent storage: create it, then attach it
- Managed disks live in the resource group, like any resource
- Detaching keeps the data — the disk can re-attach to another VM

The mental model: one disk for the system, one for the data. The O S disk appears automatically when the machine is created — Terraform never writes that block for it here. A data disk is different: it's a managed disk resource of its own, created first, and attached second. And because it's independent, you can detach it and bolt it onto a different machine later — the data survives.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 21-data-disk
              ├── README.md
              ├── main.tf
              ├── variables.tf
              ├── terraform.tf
              └── terraform.tfvars.example

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/21-data-disk
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Readme, main dot t f, variables, terraform dot t f, and the tf vars example for the password.

## S006 — CODE: main.tf lines 20-52

The network stack first — resource group, VNet on ten one forty slash sixteen, subnet, and the network interface. All familiar from earlier labs. The interface is the VM's future network card, and it's the last piece before the machine itself.

## S007 — CODE: main.tf lines 54-74

The Windows virtual machine. Nothing new in the block itself — size, credentials, image — except what's NOT here: no data disk yet. The O S disk inside is just the boot drive: read-write caching, standard S S D. Windows will see roughly a hundred twenty-seven gigabytes of C drive, and that's all.

## S008 — CODE: main.tf lines 76-96

Now the new pair. The managed disk: create option Empty — a blank disk — thirty-two gigabytes. And the attachment, a separate resource that joins disk to machine. L U N zero is its slot number, zero through sixty-three, how the guest O S will identify it. Splitting these two apart is deliberate: resize the disk, or re-attach it elsewhere, and only one resource changes.

## S009 — DIAGRAM: Disk, machine, and the LUN that joins them

The whole story in one picture: the resource group holds the machine and the blank managed disk side by side — neither knows the other exists. The attachment resource is the join: disk into machine at L U N zero. Only when that third resource exists does Windows see its second drive.

## S010 — TERMINAL: terraform apply

Apply time — seven resources, and watch the order: machine first, disk second, attachment last. The dependency chain Terraform inferred from the I D references. In the portal afterward, the machine's Disks blade shows two entries — the boot disk, and disk data zero one at L U N zero.

## S011 — CONCEPT: Common pitfall — treating the disk as VM config

- The attachment is a real resource — deleting the VM does not detach the disk
- Changing the attachment's LUN is an in-place update; changing the disk id is a replace
- Host caching: None for write-heavy disks, ReadWrite for read-heavy
- Detached disks keep billing — delete what you don't need

Here are the pitfalls in this lab. One: the attachment is a real resource — deleting the v m does not detach the disk. The disk's independence cuts both ways: the attachment survives as its own resource. Two: changing the attachment's l u n is an in-place update; changing the disk i d is a replace. The slot number can move; a different disk means the old one is replaced. Three: host caching — none for write-heavy disks, read write for read-heavy. Match the caching mode to the workload's read and write pattern. Four: detached disks keep billing — delete what you don't need. A detached disk keeps existing, and keeps costing, until you delete it explicitly.

## S012 — RECAP: recap

- azurerm_managed_disk: blank standalone disk (create_option Empty)
- Attach with azurerm_virtual_machine_data_disk_attachment
- LUN 0-63 identifies the disk inside the guest OS
- Separate resources: resize or re-attach without touching the other
- OS disk is automatic; the data disk is what YOU manage

Quick recap — five things. One: azurerm managed disk — a blank standalone disk, with create option empty. Two: attach with the virtual machine data disk attachment resource. Three: l u n zero through sixty three identifies the disk inside the guest o s. Four: separate resources mean you can resize or re-attach without touching the other. Five: the o s disk is automatic — the data disk is what you manage.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/21-data-disk
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
