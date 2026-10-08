# Script — Lab 02: Your First Resource: The Azure Storage Account

*Azure Foundations — Lab 02. Generated from `source/terraform-inventory.json` +
`source/source-manifest.json` (ACTIVE_LAB = `section-01-foundations/02-storage-account`).*

---

## S001 — TITLE

**Your First Resource: The Azure Storage Account**

Welcome back. In lab one, we proved Terraform could sign in to Azure. Now we put
that identity to work. In this lesson, we create your first real resources: a
resource group, and a storage account. Along the way, you'll learn resource
blocks, locals, and a stateful random suffix that keeps your names stable. By
the end, Terraform will have created real infrastructure in your subscription.

## S002 — CONCEPT: What you'll learn

- resource blocks — where Terraform creates and manages real infrastructure
- locals — compute names once, reuse them everywhere
- The random provider — a suffix saved in state, stable across every run

Here's what you'll learn in this lesson — three things. One: resource blocks — where Terraform creates and manages real infrastructure. Two: locals — compute names once, and reuse them everywhere. Three: the random provider — a suffix saved in state, stable across every run.

## S003 — CONCEPT: Where this lab fits

- Lab 2 of the Foundations section
- Lab 1 proved Terraform's identity
- Now Terraform creates its first real resources

This is lab two of the Foundations section. Lab one proved who Terraform is.
This lab is what Terraform can do with that identity: create something real. We
start small, with a resource group and a storage account, the foundation almost
every Azure project is built on.

## S004 — CONCEPT: Storage account naming rules

- Globally unique across ALL of Azure
- 3–24 characters, lowercase letters and numbers only
- We let Terraform generate the unique part

Before writing code, one rule to know. Storage account names must be globally
unique across all of Azure, between three and twenty four characters, lowercase
letters and numbers only. Nobody can guarantee that by hand, so we'll let
Terraform generate the unique part for us, with a random suffix.

## S005 — CONCEPT: Where to find this lab

*GitHub breadcrumb: `RIT-MESH / Terraform-Azure-Labs-and-Case_Studies → labs →
section-01-foundations → 02-storage-account (README.md, main.tf, terraform.tf)`
+ direct public URL. Never read aloud.*

You can find this lab in the course GitHub repository under Section 1,
Foundations. The direct link is in the video description. The lab is three
small files: main dot T F holds the entire configuration, terraform dot T F
pins the providers, and the README explains what you'll see in the Azure portal
afterwards.

## S006 — CODE: terraform.tf (lines 1–15, highlight 10–13)

The terraform dot T F file follows the same pattern you learned in lab one: a
minimum Terraform version, and the Azure R M provider pinned near version three
point seventy. One thing is new. We also require the random provider, version
three point six or newer. That's the provider that will generate our unique
name suffix, and Terraform downloads both providers automatically during init.

## S007 — CODE: main.tf locals (lines 8–19, highlight 10, 11, 17, 18)

Inside main dot T F, the locals block holds derived values: names we compute
once and reuse. We fix the region, East U S, and the resource group name. Then
the interesting part. The storage account name must be lowercase, so we wrap it
in the lower function, and we append a random suffix to make it globally unique.
Define a name here, and every resource below follows automatically.

## S008 — CODE: main.tf random_string (lines 24–31, highlight 27–30)

Here is the source of that suffix. The random string resource generates six
characters, no uppercase, no special characters. The key word is stateful.
Terraform saves this value in its state file, so it's generated once, then
reused on every plan and apply. If we hashed a timestamp instead, the name
would change on every run, and Terraform would try to destroy and recreate the
storage account each time.

## S009 — DIAGRAM: How the pieces connect

Here's how the pieces connect. The random string produces the suffix and saves
it in state. Locals combine it into the storage account name. The resource
group is created first, and the storage account references its name and
location. That reference is what tells Terraform the order: resource group
before storage account. And everything lands inside your Azure subscription.

## S010 — CODE: main.tf azurerm_resource_group (lines 33–38, highlight 35–38)

Now the first resource block. A resource group is a logical container for
everything else in this lab, and almost every Azure config starts with one. The
resource type is azurerm resource group, and this, its local name, is what we
use to reference it elsewhere. We give it the name and the region straight from
locals.

## S011 — CODE: main.tf azurerm_storage_account (lines 40–50, highlight 43–49)

And the storage account itself. Notice the two references: the resource group
name and location come from the resource group we just defined. That reference
is how Terraform knows the dependency, and creates them in the right order.
Account tier Standard means disk based and cost effective. Replication type
L R S keeps three copies in one data center, the cheapest option. We also
enforce T L S version one point two, and keep every blob private by default.

## S012 — CODE: main.tf outputs (lines 52–60, highlight 53, 54, 58, 59)

Finally, two outputs, just like lab one. After apply, Terraform prints the
storage account name, and its primary blob endpoint. The name proves the random
suffix worked. And the endpoint URL is handy to paste into a browser, or to
hand to a later lab that uploads blobs.

## S013 — TERMINAL: init → plan → apply → outputs

Time to run it. Terraform init now downloads two providers: Azure R M and
random. Terraform plan shows exactly what will be created: one random string,
one resource group, one storage account. Terraform apply creates all three, and
both outputs print, including the globally unique name Terraform chose. What
you see on screen is an illustrative view of what that looks like.

## S014 — CONCEPT: Common pitfall

- Timestamp-based suffixes change every run → Terraform replaces the resource
- Changing name or account_tier forces destroy + recreate — Terraform asks first

Two pitfalls to avoid in this lab. One: timestamp-based suffixes change every run —
Terraform replaces the resource. If the unique suffix comes from something that
moves, like a timestamp, every plan produces a new name, and Terraform will destroy
and recreate the storage account. The fix is exactly what this lab does: a random
string saved in state. Two: changing the name or the account tier forces a destroy
and recreate — Terraform asks first. The same caution applies to settings like the
account tier: some changes can only be applied by replacing the whole resource, so
Terraform will ask before doing it.

## S015 — RECAP

- resource blocks create and manage real infrastructure
- locals compute names once — one place to change them
- random_string is stateful: the suffix never changes between runs
- Storage account names: globally unique, 3–24 chars, lowercase + numbers
- References create dependencies: resource group before storage account

Quick recap — five things. One: resource blocks create and manage real
infrastructure. Two: locals compute names once, in one place to change them. Three:
the random string is stateful — the suffix never changes between runs. Four: storage
account names are globally unique, three to twenty four characters, lowercase letters
and numbers. Five: references create dependencies — the resource group comes before
the storage account.

## S016 — NEXT (fixed transition, verbatim)

Now that we understand how this Terraform configuration works, in the next part
of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S017 — OUTRO (centered; repo link on screen, never read aloud)

Thanks for watching. If this helped, the full lab, along with every lab in this
course, is in the GitHub repository linked below. If you'd like more lessons
like this one, give the video a like, share it with a friend who is learning
Azure, and subscribe to the channel. It really helps the course grow. Thank
you, and see you in the next lesson.