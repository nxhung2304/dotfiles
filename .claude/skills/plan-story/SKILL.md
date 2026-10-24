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
3. Break each feature into tasks as vertical slices (see Slicing and sizing). Rule: one task = one GitHub issue. Number as `<phase>.<index>` (`1.1`, `1.2`, `2.1`, ...). Give each task its blocking edges: the other tasks that must finish before it can start.
4. Show the draft as a numbered list (title, **Blocked by**, what it delivers end to end) and ask: is the granularity right (too coarse / too fine)? does each task depend only on tasks that genuinely gate it? should any be merged or split? Iterate, then wait for approval before writing (`mkdir -p specs`).

## `specs/story.md` format

```
# Story

## Phase 1: <name>
- [ ] 1.1. <title>
- [ ] 1.2. <title>

## Phase 2: <name>
- [ ] 2.1. <title>

## Dependencies
| Task | Blocked by |
| :--- | :--- |
| 1.2 | 1.1 |

## Coverage
| Feature | Tasks |
| :--- | :--- |
| F1 | 1.1, 1.2 |
```

- `Dependencies` lists only tasks that have blockers; a task not listed can start immediately. It sits outside the task lines.

- Task lines match exactly `- [ ] [number]. [title]` — `generate-issues` parses them; add nothing else on those lines.
- Titles are short and outcome-based. No implementation detail.
- `Coverage` maps every MVP ID of the chosen unit (feature or story) to its task numbers; it sits outside the task lines.
- Manual work (device checks, user tests, release decisions) goes in a `## Checklist (kiểm tay, không phải issue)` section outside the task lines, never as a task.

## Slicing and sizing (task = 1 issue)

Cut tasks as **vertical slices** (tracer bullets): each task carries one outcome through every layer it needs (schema/DB, logic, API/UI, tests), is demoable or verifiable on its own, and is sized to fit in a single fresh context window. Never split one outcome by layer (a "DB task", then a "UI task" for the same outcome).

A task is too wide and must be split when any of these holds:
- Its title joins two outcomes with "và" or "," (e.g. "Parse EPUB và ghi DB").
- It would need more than one PR-sized review pass to verify, or would not fit in one context window.
- It has a sub-list of 3+ independent behaviours (e.g. the error table in a PRD section).

Split along outcomes, each piece still a vertical slice.

**Prefactor first.** If the change is hard in the current code, make the restructuring its own early task that the others are blocked by ("make the change easy, then make the easy change").

**Wide refactor exception.** One mechanical change whose blast radius fans across the whole codebase (rename a column, retype a shared symbol) cannot land as a vertical slice. Sequence it as expand–contract: (1) expand, adding the new form beside the old; (2) migrate call sites in batches sized by blast radius (per package/directory), each batch its own task blocked by the expand; (3) contract, deleting the old form in a task blocked by every migrate batch. If batches cannot stay green alone, let them share an integration branch and block a final integrate-and-verify task.

Project scaffolding with no outcome a user can see (repo setup, CI) stays its own task; everything after it is sliced vertically.

If a task is ambiguous in scope, ask the user before splitting or merging.

## Coverage check (mechanical, before finishing)

Follow the `verify-before-claim` skill: list the MVP IDs from `prd.md` with grep, list the IDs in the `Coverage` table, and diff the two. Report any MVP ID with no task and any task that maps to no ID. Never state "all features covered" from eyeballing.

Do the same for `Dependencies`: every task number in either column must exist as a task line, and no task may (directly or through others) block itself.

## Done

Report task count per phase, the number of tasks split under Slicing and sizing, the number of tasks with blockers, and the coverage and dependency check results. Last line: `Next: /generate-issues`
