# Upload a Blob with Terraform

**Episode:** section-01-foundations/03-upload-blob
**Lesson label:** Azure Foundations — Lab 03
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/03-upload-blob
**Scope:** `main.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Upload a Blob with Terraform

In the last lesson we created a storage account. This time we put something inside it. In this lesson we upload our first real piece of data to Azure: a text file, stored as a blob, created entirely by Terraform. Along the way you'll meet two new resource types, and see dependency ordering working for you automatically.

## S002 — CONCEPT: What you'll learn

- The storage hierarchy: account → container → blob
- Two new resources: azurerm_storage_container and azurerm_storage_blob
- Inline content with source_content vs a local file with source
- How Terraform orders resources from references alone

Here's what you'll learn. One: the storage hierarchy — account, container, blob. Two: two new resources — azurerm storage container, and azurerm storage blob. Three: inline content with source content, versus a local file with source. Four: how Terraform orders resources from references alone.

## S003 — CONCEPT: Where this lab fits

- Lab 3 of the Foundations section
- Builds directly on Lab 2's storage account
- Same pattern: locals, a random suffix, references between resources

This is lab three of the Foundations section, and it builds straight on what we did in lab two. There we created an empty storage account with a random suffix in its name. Now we add a container and upload a blob into it. The pattern is the same one you already know: locals hold our values, and resources reference each other.

## S004 — CONCEPT: Blobs and containers in one minute

- Storage account — the top-level storage endpoint
- Container — a folder-like grouping of blobs
- Blob — the actual file: text, images, backups, anything
- Private access — only authorized requests can read

One minute of theory before the code. A storage account is the top level. Inside it, containers act like folders, grouping related blobs. A blob is the actual file: text, an image, a backup. We'll set our container to private access, so only authorized requests can read what's inside. That's the sensible default for real data.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 03-upload-blob
              ├── README.md
              └── main.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/03-upload-blob
```

As always, the lab lives in the course GitHub repository under Section 1, Foundations, with the direct link in the description. It's one file, main dot T F, plus a README. Everything you see in this lesson comes from that single file.

## S006 — CODE: main.tf lines 9-16

At the top, our locals block, just like lab two. Region and resource group name are plain strings. The interesting one is the storage account name. We build it from a prefix, plus a random suffix, and pass the whole thing through lower. Azure requires storage account names to be lowercase and globally unique, so this one line handles both rules.

## S007 — CODE: main.tf lines 18-25

Here's that random source. You met random string in lab two, so just one reminder: this is a stateful value. Terraform saves the generated result in its state, so it stays the same on every later plan and apply. The name never changes unless you destroy the resource. Six characters, no uppercase, no specials.

## S008 — CODE: main.tf lines 27-31

The resource group comes next, and there's nothing new here. We take the name and region from locals and create the group that will hold everything else in this lab. You've written this block twice already, and by now it should feel routine.

## S009 — CODE: main.tf lines 33-42

The storage account is also a repeat of lab two, but look closely at the two reference lines. The name and location come from the resource group we just defined. That's not just convenience. Those references are how Terraform knows the resource group must exist before the storage account. No ordering code needed. Keep that idea, because the container and blob depend on it next.

## S010 — DIAGRAM: The storage hierarchy this lab builds

Here's the whole structure we're building, in order. The resource group at the top. Inside it, the storage account with its random-suffix name. Inside the account, the uploads container. And inside the container, our blob: hello dot text. Terraform reads the references in the code and creates these in exactly this order.

## S011 — CODE: main.tf lines 44-50

Now the first genuinely new resource: azurerm storage container. Every container belongs to a storage account, and we pass that account's name in as a string. That reference puts the container after the account in the plan. And the access type is private, meaning only authorized requests can read the blobs inside. For anything real, private is the right default.

## S012 — CODE: main.tf lines 64-71

And here is the upload itself. The blob is called hello dot txt, and it lives in the uploads container we just made. Type block is the right choice for ordinary files. The interesting attribute is source content: we hand Terraform the text directly, and it creates the file in Azure for us. Content type text plain tells Azure how to serve it.

## S013 — CODE: main.tf lines 73-75

One output finishes the file. After apply, Terraform prints the blob's U R L, so you can confirm the upload landed. If you open that U R L in a browser on a private container, you'll get a four oh four, because anonymous reads are off. That's the private access type doing its job, not a failure.

## S014 — TERMINAL

Time to run it. Terraform init pulls both providers, Azure R M and random. Then apply walks the chain in order: resource group first, then the storage account, then the container and the blob. Four resources, one clean run, and the blob U R L printed at the end as proof.

## S015 — CONCEPT: Common pitfall — timestamp() in uploaded content

- source_content holds "Uploaded: ${timestamp()}" — captured into state at apply
- Next plan: the clock has moved → Terraform wants to UPDATE the blob, every run
- In-place update, not a replace — harmless here, noisy everywhere
- Rule: keep volatile values out of attributes that are diffed against state

Here are the pitfalls in this lab. One: the source content holds a timestamp — it is captured into state at apply. At apply time, Terraform freezes that text into its state, and the clock stops mattering to Terraform. Two: on the next plan the clock has moved, so Terraform wants to update the blob — every single run. The content no longer matches what's in state, so Terraform proposes the same change again and again. Three: it's an in-place update, not a replace — harmless here, but noisy everywhere. Nothing breaks; you just get churn on every plan. Four: the rule — keep volatile values out of attributes that are diffed against state. Timestamps and other moving values don't belong in anything Terraform compares with state, unless you actually want that churn.

## S016 — RECAP

- Storage hierarchy: account → container → blob
- azurerm_storage_container + azurerm_storage_blob create both levels
- source_content uploads inline text; source uploads a local file
- References between resources order the plan — no depends_on needed yet
- Volatile values in diffed attributes cause drift on every plan

Quick recap — five things. One: the storage hierarchy — account, container, blob. Two: azurerm storage container and azurerm storage blob create both levels. Three: source content uploads inline text, while source uploads a local file. Four: references between resources order the plan — no depends on needed yet. Five: volatile values in diffed attributes cause drift on every plan.

## S017 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S018 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/03-upload-blob
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
