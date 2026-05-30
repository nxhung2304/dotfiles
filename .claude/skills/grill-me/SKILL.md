---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

**Termination:** Stop when one of these conditions is met:
- All branches of the decision tree have been resolved
- The user explicitly signals completion ("done", "proceed", "that's enough", "ship it")
- You have asked 15+ questions with no unresolved branches remaining

When done, output a **Decision Summary** — a bullet list of every decision made with its rationale — so the user can paste it into their spec.
