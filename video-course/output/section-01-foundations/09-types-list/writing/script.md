# Lists and For-Expressions

**Episode:** section-01-foundations/09-types-list
**Lesson label:** Azure Foundations — Lab 09
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/09-types-list
**Scope:** `main.tf` (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE: Lists and For-Expressions

Writing three subnet blocks by hand works. Writing thirty doesn't. In this lesson we meet the list, Terraform's first collection type, and the for expression that turns a list of values into repeated configuration, automatically.

## S002 — CONCEPT: What you'll learn

- The list type: ordered, index-addressed values
- for-expressions: transforming a list into new data
- dynamic blocks: generating nested blocks from a collection
- Three subnets from one list — add a value, get a subnet

Here's what you'll learn. One: the list type — ordered, index-addressed values. Two: for-expressions — transforming a list into new data. Three: dynamic blocks — generating nested blocks from a collection. Four: three subnets from one list — add a value, and you get a subnet.

## S003 — CONCEPT: Where this lab fits

- Lab 9 of the Foundations section
- Lab 6 typed subnets by hand — this lab generates them
- Collections start here; maps come next in Lab 10

This is lab nine of the Foundations section. Back in lab six we typed each subnet by hand, inside the V N E T. That's fine for two. This lab replaces the repetition with data: one list of prefixes, one for expression, three identical subnets. Next lab does the same for maps.

## S004 — CONCEPT: Lists in one minute

- A list is ordered and index-addressed: ["a", "b", "c"]
- list[0] is the first element — indexes start at zero
- Every element shares one type: list(string), list(number)...
- Repetition in Terraform = data in a collection + an expression

Sixty seconds on lists. A list holds values in order, addressed by index, starting at zero. In Terraform every element has the same type: a list of strings here, a list of numbers there. And the big idea for this lab: whenever you find yourself writing the same block twice, the professional move is to put the differences into a collection, and let an expression generate the blocks.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 09-types-list
              ├── README.md
              ├── main.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/09-types-list
```

You'll find this lab in the course GitHub repository under Section 1, Foundations, link in the description. Two files: main dot T F, and terraform dot T F with the pins, following last lab's split layout.

## S006 — CODE: main.tf lines 9-13

First, the data. Subnet prefixes is a list of three C I D R strings, in square brackets, comma separated. Ordered: index zero is ten fifty dot one, index one is ten fifty dot two. This list is the single source of truth. Everything else in this file derives from it.

## S007 — CODE: main.tf lines 15-21

Now the for expression, the heart of the lab. Read it as: for each index I and each value P in the prefixes list, produce an object with a name and a prefix. The name is computed from the index: tier one, tier two, tier three. The output is a list of objects, richer than the list we started with. Same data in, structured data out. That's the whole trick.

## S008 — CODE: main.tf lines 23-34

The resource group and virtual network are familiar shapes by now: locals feed the names, references order the plan. The network's address space is, fittingly, a list of C I D R blocks too. The new part is what's coming inside this block, so let's look at that next.

## S009 — CODE: main.tf lines 36-45

Here's the dynamic block. It says: for each entry in this collection, emit a subnet block. The collection is our list of objects, converted to a map keyed by name, because for each needs a map or a set. Inside content, subnet dot value dot name and dot prefix pull the fields from each entry. Three list elements, three subnets. Add a fourth prefix to the list, and the next plan creates it. No new code.

## S010 — DIAGRAM: From one list to three subnets

Here's the pipeline in one picture. A list of three prefixes. The for expression enriches it into three objects with computed names. The dynamic block turns each object into a real subnet inside the V N E T. Data flows left to right, and at every stage the list is still the only thing you edit.

## S011 — CODE: main.tf lines 47-50

One output proves the projection: a for expression over the subnets list, picking just the names. After apply you'll see tier one, tier two, tier three, all generated from data.

## S012 — TERMINAL

Apply time. The plan shows the group, the network, and all three subnets generated from the list. Then the output prints their names. Three resources' worth of subnets, one line of data.

## S013 — CONCEPT: Common pitfall — repeating blocks instead of using data

- Five copy-pasted subnet blocks = five places to mistype a prefix
- Collections + for-expressions make repetition data, not code
- dynamic blocks shine when a nested block must repeat
- Next lab: maps when each entry needs its own identity

Here are the pitfalls in this lab. One: five copy-pasted subnet blocks mean five places to mistype a prefix. Five hand-typed blocks are also five edits for every change. Two: collections and for expressions make repetition data, not code. The list plus for expression pattern collapses the repetition into a single source of truth. Three: dynamic blocks shine when a nested block must repeat. A dynamic subnet block emits one nested block per collection entry. Four: coming next — maps, when each entry needs its own identity. Lists are perfect for interchangeable entries; when entries need names you reference later, maps fit better — and that's exactly where we're headed.

## S014 — RECAP

- Lists are ordered, index-addressed collections of one type
- for expressions transform a list into richer data (list of objects)
- dynamic "subnet" {} emits a nested block per collection entry
- for_each iterates a map/set — convert lists with a { for ... } expression
- Adding infrastructure = adding data, not repeating code

Quick recap — five things. One: lists are ordered, index-addressed collections of one type. Two: for expressions transform a list into richer data, like a list of objects. Three: dynamic subnet emits a nested block per collection entry. Four: for each iterates a map or set — convert lists with a for expression. Five: adding infrastructure means adding data, not repeating code.

## S015 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S016 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/09-types-list
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
