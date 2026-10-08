# Passing Secret Values

**Episode:** section-01-foundations/20-secret-values
**Lesson label:** Azure Foundations — Lab 20
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/20-secret-values
**Scope:** ACTIVE_LAB sources only. No other lab's resources appear.

---

## S001 — TITLE: Passing Secret Values

Lab 17 masked the admin password with one flag and moved on. This lesson gives secrets their full treatment: the three ways to pass a sensitive value, what masking really does, and the one place your secret still ends up in plain text.

## S002 — CONCEPT: What you'll learn

- sensitive variables: masked in plan/apply logs, still usable in code
- Three ways to supply a secret: tfvars (gitignored), TF_VAR_ env var, -var
- What masking does — and the state-file caveat
- tfvars.example as a template; the real file never committed

Here's what you'll learn. One: sensitive variables — masked in plan and apply logs, still usable in code. Two: three ways to supply a secret — a gitignored t f vars file, a T F underscore V A R environment variable, or var on the command line. Three: what masking does — and the state-file caveat. Four: t f vars dot example as a template — the real file never committed.

## S003 — CONCEPT: Where this lab fits

- Lab 20 of the Foundations section
- Lab 17 used one sensitive variable in passing — now the full picture
- Same VM shape as Lab 17, minus the public IP and NSG — the secret is the subject

This is lab twenty, and the configuration is deliberately familiar: the same V M shape as lab seventeen, minus the public address. That's because the machine isn't the subject — the password is. How it arrives, how it's masked, and where it still lives in plain text.

## S004 — CONCEPT: Three paths to a secret

- terraform.tfvars — auto-loaded, but must be gitignored for secrets
- TF_VAR_<name> environment variable — per-shell, never touches disk
- -var on the command line — convenient, but lands in shell history
- sensitive = true masks logs; the state file remains plain text

Terraform gives you three doors for a secret, and each has a price. The t f vars file is convenient and auto-loaded — but it's a file, so it belongs in git ignore, never in the repository. The T F V A R environment variable keeps the secret off disk entirely, but only for that shell session. The var flag is quick for tests — and it lands in your shell history, so think twice. And whatever path you choose, the sensitive flag only masks the logs. The state file keeps the value in plain text — protect it accordingly.

## S005 — CONCEPT: Where to find this lab

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 20-secret-values
              ├── README.md
              ├── main.tf
              ├── terraform.tf
              ├── variables.tf
              └── terraform.tfvars.example

https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
/tree/master/labs/section-01-foundations/20-secret-values
```

As always, the lab is in the course GitHub repository under Section 1, Foundations, with the link in the description. Note the file list: a terraform dot t f vars dot example, not a real one — the real t f vars is gitignored, by design.

## S006 — CODE: main.tf lines 9-20

The two variables. Admin username — not secret, just a default of azureadmin. And admin password: type string, sensitive true, no default. Terraform will mask this value in every log, and prompt for it if nothing supplies one. The declaration alone already changes what appears on screen.

## S007 — CODE: main.tf lines 61-81

The machine, and the two lines that matter: admin username and admin password, both flowing from the variables. The password reaches the V M exactly like any other attribute — but because the variable is sensitive, it never prints in plain text in the plan or the apply.

## S008 — CODE: terraform.tfvars.example lines 1-1

This is the example file — one line, an obviously fake password. Its whole job is documentation: it shows the shape a real t f vars file needs. The real file, terraform dot t f vars, holds the actual password and lives in git ignore, where no push can ever reach it.

## S009 — DIAGRAM: Three paths, one masked destination

The three delivery paths drawn out: a gitignored t f vars file, the T F V A R environment variable, and the command line var — all feeding the same sensitive variable, which masks the value in every log before it reaches the machine.

## S010 — TERMINAL: terraform apply

Apply time — five resources, and one detail that proves the flag worked: nowhere in that log does the password appear. The variable was sensitive, so Terraform printed a placeholder instead. The machine got the real value; the terminal got nothing. That's masking working exactly as intended.

## S011 — CONCEPT: Common pitfall — trusting the mask with the secret itself

- sensitive masks logs — the value still sits in state, in plain text
- Never commit a real tfvars — ship the .example, gitignore the real file
- -var leaks into shell history; TF_VAR_ stays per-shell
- Rotate any secret that ever reached a log, a file, or a history

Here are the pitfalls in this lab. One: sensitive masks logs — the value still sits in state, in plain text. The mask protects the log, nothing more; protect the state file like the secret it holds. Two: never commit a real t f vars file — ship the example, and gitignore the real one. The file that carries the real value stays local; the committed template documents its shape. Three: a var flag leaks into shell history; a t f underscore v a r environment variable stays per-shell. What you type on the command line is recorded; environment variables are not. Four: rotate any secret that ever reached a log, a file, or a history. If a secret leaked, the fix isn't masking — it's rotation.

## S012 — RECAP: recap

- sensitive = masked in plan/apply logs — not encryption
- Three paths for a secret: gitignored tfvars, TF_VAR_ env var, -var flag
- tfvars.example documents the shape; the real file never gets committed
- The state file still holds the value in plain text — protect it
- A secret that reached a log, file, or history is a rotated secret

Quick recap — five things. One: sensitive means masked in plan and apply logs — not encryption. Two: three paths for a secret — a gitignored t f vars file, a t f underscore v a r environment variable, or a var flag. Three: the t f vars example documents the shape; the real file never gets committed. Four: the state file still holds the value in plain text — protect it. Five: a secret that reached a log, a file, or a history is a rotated secret.

## S013 — NEXT: next up

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S014 — CONCEPT: Thanks for watching

```
github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies
tree/master/labs/section-01-foundations/20-secret-values
```

Thanks for watching. If this helped, the full lab, along with every lab in this course, is in the GitHub repository linked below. If you'd like more lessons like this one, give the video a like, share it with a friend who is learning Azure, and subscribe to the channel. It really helps the course grow. Thank you, and see you in the next lesson.
