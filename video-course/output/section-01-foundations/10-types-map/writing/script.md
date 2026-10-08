# Maps and for_each

**Episode:** section-01-foundations/10-types-map
**Lesson label:** Azure Foundations — Lab 10
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/10-types-map
**Scope:** `main.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Maps and for_each

Last lesson repeated blocks from a list. But lists address by position, and infrastructure usually addresses by role: web, app, data. In this lesson we meet the map, and the for each meta argument, the idiomatic way to create one resource per entry.

## S002 — CONCEPT: What you'll learn

- The map type: meaningful keys, each holding a value or object
- for_each over a map: one resource per key
- each.key and each.value inside the resource block
- Why maps beat lists when entries have identity

Here's what you'll learn. One: the map type — meaningful keys, each holding a value or an object. Two: for each over a map — one resource per key. Three: each dot key and each dot value inside the resource block. Four: why maps beat lists when entries have identity.

## S003 — CONCEPT: Where this lab fits

- Lab 10 of the Foundations section
- Lab 9's list becomes a map — entries now have names
- Subnets become separate resources with for_each (vs inline in Lab 6)

This is lab ten, the last of the collection-type pair. In lab nine, a list generated subnets by position. Here a map generates them by role: web, app, and data. And notice the shape: each subnet is now its own standalone resource, not an inline block. That's the flexible version lab six promised was coming.

## S004 — CONCEPT: Lists vs maps: position vs identity

- List: "give me the 2nd one" — index-addressed, entries interchangeable
- Map: "give me web" — key-addressed, entries have meaning
- for_each on a map: remove a key → that resource is destroyed, others untouched
- The map key is how Terraform tracks each instance in state

The rule for choosing between last lesson and this one is simple. If you address entries by position, use a list. If you address them by role or name, use a map. The reason it matters is state: for each over a map creates one tracked instance per key. Delete the app key from the map, and Terraform destroys exactly the app subnet, leaving web and data alone. That kind of surgical change is what makes maps the professional default for repeated resources.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 10-types-map
              ├── README.md
              ├── main.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/10-types-map
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Main dot T F and terraform dot T F, same split layout as the last two labs.

## S006 — CODE: main.tf lines 17-28

First the data, and it's a different shape this time. Subnets is a map: three keys, web, app, and data, and each value is an object with a prefix and an N S G flag. Compare this to last lab's list: there, position told you what a subnet was. Here, the key does. You'll see how much that buys us in a moment.

## S007 — CODE: main.tf lines 30-43

The resource group and virtual network are the familiar opening pair, same reference chains as the last several labs. One network, ten sixty dot zero dot zero slash sixteen, ready to hold three subnets. Nothing new here, so let's get to the main event.

## S008 — CODE: main.tf lines 45-55

This is the lesson: one subnet resource, no list, no dynamic block. For each equals the map, and Terraform creates one instance per key. Inside the block, each dot key is the role name, web, app, or data, and it builds the subnet name: snet dash web. Each dot value is that key's object, and the address prefixes line pulls its prefix. Three map entries, three real resources, one resource block.

## S009 — DIAGRAM: One resource block, three instances — one per key

Here's what for each actually built. The map has three entries, so the single azurerm subnet resource becomes three instances: snet web, snet app, and snet data, each tracked in state under its key. Change the web entry's prefix, and only web is touched. Delete the data key, and only data is destroyed. Identity, not position.

## S010 — CODE: main.tf lines 57-60

The output closes with a for expression over the created resources. K is the key, S is each instance, and the result is a map from role to subnet I D. After apply you can hand any downstream module the data subnet's I D by asking for it by name.

## S011 — TERMINAL

Apply time, and the plan tells the story: three separate subnet resources, each with its own address, created from one block. The output maps every role to its I D. That's for each doing in resources what for expressions did in data.

## S012 — CONCEPT: Common pitfall — lists where identity matters

- A list-based for_each re-indexes on removal: entries shift, state churns
- Remove "web" from a list → every later subnet's address changes
- Remove "web" from a map → only web is destroyed
- The unused nsg flag is deliberate — Lab 11 turns this map into a variable

Here are the pitfalls in this lab. One: a list-based for each re-indexes on removal — entries shift, and state churns. If you remove the first entry of a list, every following entry slides down an index. Two: remove web from a list, and every later subnet's address changes. Terraform thinks every subnet changed, even though nothing real did. Three: remove web from a map, and only web is destroyed. Map keys are stable names, so state follows the role, not the position. Four: the unused n s g flag is deliberate — lab eleven turns this map into a variable. The shape is already production-ready for it.

## S013 — RECAP

- Maps are key-addressed: web, app, data — role, not position
- for_each = map creates one resource instance per key
- each.key names the instance; each.value carries its object
- Instance identity in state = the map key (surgical changes)
- Prefer maps over lists whenever entries have identity

Quick recap — five things. One: maps are key-addressed — web, app, data — by role, not position. Two: for each over a map creates one resource instance per key. Three: each dot key names the instance; each dot value carries its object. Four: instance identity in state is the map key — changes stay surgical. Five: prefer maps over lists whenever entries have identity.

## S014 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S015 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/10-types-map
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
