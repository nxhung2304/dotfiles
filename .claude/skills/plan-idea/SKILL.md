---
name: plan-idea
model: claude-opus-5-5
allowed-tools: Read, Grep, Glob, Bash(ls:*), Bash(mkdir -p *), Write
description: Step 1 of the plan-* flow. Interactive discussion to turn a rough project idea into a clear problem, users, constraints and non-goals, then save it to specs/idea.md. Use when the user has a new project idea and says "plan-idea", "tôi có ý tưởng", "bàn ý tưởng dự án", "làm rõ ý tưởng", or starts a project from scratch.
---

# Plan Idea

Flow: **plan-idea** → plan-prd → plan-stack → plan-story → generate-issues

Discussion only. Produces `specs/idea.md`; never writes the PRD, techstack or story.

## Steps

1. Read `CLAUDE.md`, `README.md` and anything under `specs/` that already exists. If `specs/idea.md` exists, summarize it and ask whether to continue or restart.
2. Ask one question at a time, always with a recommended answer; the user confirms or overrides. Cover, in this order:
   - **Problem**: what hurts today, for whom.
   - **Users**: who uses it, how often, on which platform.
   - **Core job**: the one thing it must do well.
   - **Constraints**: deadline, budget, team size, existing systems, legal/data limits.
   - **Non-goals**: what it will deliberately not do.
   - **Success**: how the user will know it worked.
3. Push back when an assumption looks wrong or the scope looks too big for the constraints. Don't just agree.
4. Anything the user has not confirmed is written as an assumption, not as a fact.
5. When the six topics are covered, show a draft of `specs/idea.md` and wait for approval. Only then write it (`mkdir -p specs`). Never overwrite an existing file without asking.

## `specs/idea.md` format

- `## Problem`, `## Users`, `## Core job`, `## Constraints`, `## Non-goals`, `## Success`
- `## Assumptions` — unconfirmed items, one line each
- `## Open questions` — what is still undecided

## Done

Report the file written and the open questions. Last line: `Next: /plan-prd`
