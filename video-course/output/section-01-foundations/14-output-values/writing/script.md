# Output Values

**Episode:** section-01-foundations/14-output-values
**Lesson label:** Azure Foundations — Lab 14
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/14-output-values
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Output Values

Every lab so far has ended the same way: values you only learn after apply — a resource I D, a private I P, an address Azure chose. This lesson makes those exports the subject: the output block, in its three costumes.

## S002 — CONCEPT: What you'll learn

- output blocks: plain, described, and sensitive
- Outputs are the configuration's public API after apply
- terraform output <name> reads a value back on demand
- What sensitive masks — and what it doesn't

Here's what you'll learn. One: output blocks — plain, described, and sensitive. Two: outputs are the configuration's public API after apply. Three: terraform output, followed by a name, reads a value back on demand. Four: what sensitive masks — and what it doesn't.

## S003 — CONCEPT: Where this lab fits

- Lab 14 of the Foundations section
- Outputs have appeared since Lab 4 — now the full treatment
- Computed values like Lab 13's private IP are exactly what outputs are for

This is lab fourteen. We've used outputs casually since lab four — a subnet I D, a private I P. Today they're the subject: how to declare them, how to read them back, and how to keep a secret from printing itself into your terminal.

## S004 — CONCEPT: Outputs are the configuration's API

- output blocks expose values after apply — to you, scripts, other configs
- description documents what the value is and why it exists
- sensitive = true masks the value in plan/apply logs
- terraform output <name> reads one; terraform output reads all

Think of outputs as the configuration's public interface. Everything inside — resources, attributes, computed addresses — is private until you declare an output for it. A description tells the next reader what the value means. Sensitive marks values that must not print in plain text. And after apply, the terraform output command is how you — or a script, or another configuration — read them back.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 14-output-values
              ├── README.md
              ├── main.tf
              ├── outputs.tf
              └── terraform.tf

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/14-output-values
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. The interesting file this time is outputs dot t f — main dot t f just builds a storage account to expose.

## S006 — CODE: main.tf lines 21-34

The subject of our outputs: a storage account. Its name embeds a random suffix from the stateful random string you met in lab five — stable across plans. Standard tier, L R S replication. Deliberately ordinary, because the lesson lives in outputs dot t f.

## S007 — CODE: outputs.tf lines 1-12

The first two outputs. The storage account's name — with a description, which changes nothing at runtime but tells the next reader what the value is. And the blob endpoint, a U R L you can paste straight into a browser. Plain outputs like these print in full after every apply.

## S008 — CODE: outputs.tf lines 14-18

The third output is different: sensitive equals true. This is the account's primary access key — a real secret. With that one flag, Terraform masks the value in every plan and apply log. The value still exists and still flows to whoever reads the output. It just refuses to print itself in plain text.

## S009 — DIAGRAM: One storage account, three outputs — one masked

Drawn out: one storage account exposing three outputs. The name with its description, the blob endpoint, and the access key — marked sensitive, so it flows but never prints in plain text.

## S010 — TERMINAL: terraform apply

Apply time, and look at the outputs block. Two values print in full — the name and the blob endpoint. The access key doesn't: it shows as sensitive, masked by the flag we set. The value isn't gone. Ask for it by name, and terraform output hands it over. Masked in logs, available on demand.

## S011 — CONCEPT: Common pitfall — trusting sensitive too much

- sensitive masks logs only — the value still sits in state, in plain text
- Don't output secrets that no downstream consumer needs
- terraform output <name> prints the real value on demand — by design
- State-file protection is a separate concern, not this flag's job

Here are the pitfalls in this lab. One: sensitive masks logs only — the value still sits in state, in plain text. The flag protects plan and apply output, nothing more. Two: don't output secrets that no downstream consumer needs. Expose only what someone downstream actually uses. Three: terraform output, followed by a name, prints the real value on demand — by design. So build the habit of treating the state file as the sensitive artifact it is. Four: state-file protection is a separate concern — not this flag's job. Marking something sensitive doesn't secure it; it just keeps it out of the log.

## S012 — RECAP: recap

- output blocks expose values after apply — the configuration's API
- description documents; sensitive masks in logs
- terraform output <name> reads values back on demand
- Computed values (Azure's choices) are prime output candidates
- Masked is not encrypted — state is still plain text

Quick recap — five things. One: output blocks expose values after apply — the configuration's public interface. Two: description documents; sensitive masks in logs. Three: terraform output, followed by a name, reads values back on demand. Four: computed values — Azure's choices — are prime output candidates. Five: masked is not encrypted — state is still plain text.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/14-output-values
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
