---
name: plan-story
model: claude-sonnet-5-5
allowed-tools: Read, Grep, Glob, Bash(ls:*), Bash(mkdir -p *), Bash(grep:*), Write, Skill
description: Step 4 of the plan-* flow. Breaks the MVP features in specs/prd.md into numbered tasks and writes specs/story.md in the format generate-issues reads (`- [ ] [number]. [title]`), with a coverage check that every MVP feature has a task. Use when the user says "plan-story", "tạo story.md", "chia PRD thành task", "prd to story".
---

# Plan Story

Flow: plan-idea → plan-prd → plan-stack → **plan-story** → generate-issues

## Steps

1. Read `specs/prd.md` (required) and `specs/techstack.md` (if present). If the PRD is missing, stop and say: run `/plan-prd` first. If `specs/story.md` exists, ask whether to update or restart; never overwrite without asking.
2. Identify the PRD's unit of coverage: the ID family that lists the MVP work with a priority (e.g. `F#`, or `US-xx` with `P0`). If the PRD has several families (e.g. `US-xx` and `FR-x`), ask which one is the unit; the other families serve as detail for writing tasks. Group the MVP items into phases (foundation first, then features in dependency order). Skip features marked `Later`.
3. Break each feature into tasks. Rule: one task = one GitHub issue. Split a task whenever its scope is wide (see Sizing). Number as `<phase>.<index>` (`1.1`, `1.2`, `2.1`, ...).
4. Show the draft and wait for approval before writing (`mkdir -p specs`).

## `specs/story.md` format

```
# Story

## Phase 1: <name>
- [ ] 1.1. <title>
- [ ] 1.2. <title>

## Phase 2: <name>
- [ ] 2.1. <title>

## Coverage
| Feature | Tasks |
| :--- | :--- |
| F1 | 1.1, 1.2 |
```

- Task lines match exactly `- [ ] [number]. [title]` — `generate-issues` parses them; add nothing else on those lines.
- Titles are short and outcome-based. No implementation detail.
- `Coverage` maps every MVP ID of the chosen unit (feature or story) to its task numbers; it sits outside the task lines.
- Manual work (device checks, user tests, release decisions) goes in a `## Checklist (kiểm tay, không phải issue)` section outside the task lines, never as a task.

## Sizing (task = 1 issue)

A task is too wide and must be split when any of these holds:
- Its title joins two outcomes with "và" or "," (e.g. "Parse EPUB và ghi DB").
- It touches more than one layer that can be reviewed separately (parser, core logic, DB, UI, CI).
- It would need more than one PR-sized review pass to verify.
- It has a sub-list of 3+ independent behaviours (e.g. the error table in a PRD section).

Keep a task whole when it is one outcome that a single reviewer can check in one pass.
If a task is ambiguous in scope, ask the user before splitting or merging.

## Coverage check (mechanical, before finishing)

Follow the `verify-before-claim` skill: list the MVP IDs from `prd.md` with grep, list the IDs in the `Coverage` table, and diff the two. Report any MVP ID with no task and any task that maps to no ID. Never state "all features covered" from eyeballing.

## Done

Report task count per phase, the number of tasks split under Sizing, and the coverage result. Last line: `Next: /generate-issues`
