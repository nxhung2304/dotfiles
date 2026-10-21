---
name: plan-stack
model: claude-opus-5-5
allowed-tools: Read, Grep, Glob, Bash(ls:*), Bash(mkdir -p *), Write, WebSearch, WebFetch
description: Step 3 of the plan-* flow. Chooses the techstack and architecture for the MVP in specs/prd.md, compares options with trade-offs, and writes specs/techstack.md (optionally specs/ERD.md / specs/architecture.md). Use when the user says "plan-stack", "chọn techstack", "chọn công nghệ", "thiết kế kiến trúc", or has a PRD and needs to decide what to build it with.
---

# Plan Stack

Flow: plan-idea → plan-prd → **plan-stack** → plan-story → generate-issues

Answers "what to build it with". Choices follow the MVP scope in the PRD, not habit.

## Steps

1. Read `specs/prd.md`. If missing, stop and say: run `/plan-prd` first. Also read `specs/idea.md` (constraints: team, deadline, budget) and `CLAUDE.md`.
2. If the repo already has code, detect the existing stack (`Gemfile`, `package.json`, `pubspec.yaml`, `go.mod`, `requirements.txt`, ...) and treat it as the default; changing it needs a stated reason.
3. For each decision area the PRD needs (client/platform, backend, database, auth, hosting/deploy, third-party services, testing), one at a time:
   - Lay out 2–3 options with trade-offs against the PRD features and the team's constraints.
   - Give a recommendation; the user confirms or overrides.
4. Verify every claim about a library, version, limit or price from its docs (WebSearch/WebFetch) or the repo. What cannot be verified is labelled a guess with a confidence level.
5. Show the draft and wait for approval before writing (`mkdir -p specs`).
6. Write `specs/ERD.md` or `specs/architecture.md` only if the PRD has data relationships or components that need them, and only after asking.

## `specs/techstack.md` format

- `## Summary` — the chosen stack in one table: area → choice.
- `## Decisions` — per area: choice, why, options rejected and why.
- `## Constraints & risks` — known limits, things to test early.
- `## Open questions`

## Rules

- Each decision names the PRD feature(s) or constraint that drives it.
- No feature scope changes here; if the stack cannot support a PRD feature, report it and send the user back to `plan-prd`.

## Done

Report the file(s) written and any PRD conflict found. Last line: `Next: /plan-story`
