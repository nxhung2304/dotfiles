---
name: plan-prd
model: claude-opus-5-5
allowed-tools: Read, Grep, Glob, Bash(ls:*), Bash(mkdir -p *), Write
description: Step 2 of the plan-* flow. Writes specs/prd.md (goals, users, MVP scope, numbered features with testable acceptance criteria) from specs/idea.md through a short Q&A. Use when the user says "plan-prd", "viết PRD", "tạo prd", "chốt phạm vi MVP", or has an idea file and wants requirements.
---

# Plan PRD

Flow: plan-idea → **plan-prd** → plan-stack → plan-story → generate-issues

Answers "what to build and for whom". No technology decisions here — those belong to `plan-stack`.

## Steps

1. Read `specs/idea.md`. If missing, stop and say: run `/plan-idea` first (or ask the user to describe the idea and offer to continue without it, labelling everything as assumption).
2. Read `CLAUDE.md` and any existing `specs/prd.md`. If a PRD exists, ask whether to update or restart; update in place, never overwrite wholesale.
3. Ask one question at a time, with a recommended answer, only about what `idea.md` leaves open. Settle:
   - **MVP scope**: what is in, what is explicitly later.
   - **Features**: split each into the smallest user-visible unit.
   - **Acceptance criteria**: for each MVP feature, checks that can be tested yes/no.
4. Show the draft and wait for approval before writing (`mkdir -p specs`).

## `specs/prd.md` format

- `## Goals` and `## Non-goals`
- `## Users` — who and their main task
- `## MVP scope` — in / out (later)
- `## Features` — each feature/story gets a stable ID, a one-line description, and an `Acceptance criteria` checkbox list, plus a priority (`MVP`/`Later`, or `P0`/`P1`...). If the PRD already has an ID scheme (`US-01`, `FR-1`, ...), keep it; otherwise use `F1`, `F2`, ...
- `## Open questions`

## Rules

- No library, framework, database or hosting choice in the PRD. If the user raises one, note it under `Open questions` for `plan-stack`.
- IDs never change once written; `plan-story` traces tasks back to them.
- A PRD written elsewhere (chat, another tool) is accepted as is: update it in place, don't force a restructure beyond moving tech decisions out.
- Unconfirmed items are labelled assumptions.

## Done

Report the file written, the MVP feature count and open questions. Last line: `Next: /plan-stack`
