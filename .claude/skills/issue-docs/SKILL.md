---
name: issue-docs
description: Save or update the linked doc files for a piece of work under specs/issues/<n>-<slug>/ — choosing only the files the current stage actually needs (issue.md, investigate.md, implement.md, testcases.md, report.md) and reusing files that already exist instead of recreating them. Works for any task (bug, feature, improvement, proposal waiting for approval). Use when the user wants to save, persist, or "ghi lại" a discussion or investigation into specs/issues ("lưu vào specs/issues", "tạo file issue", "ghi vào spec để làm sau", "save this so I can clear the chat"), when another skill (e.g. fix-issue) reaches its scaffold step, or when the user asks to update these files after new findings.
---

# Issue Docs

Persist what a conversation produced into linked files under `specs/issues/`, so the work can be picked up later without the chat. Create only what the current stage needs; reuse what already exists.

## Who triggers it

- **Directly by the user** — the request itself ("lưu vào specs/issues", "ghi lại") is the confirmation. Don't ask again.
- **From another skill** (e.g. `fix-issue` Phase 3) — the calling skill owns any gate before writing. Follow it, then run this skill.

## Step 1 — Find what already exists

Before writing anything, look for existing docs for this work:
- A folder `specs/issues/<n>-*/` or `specs/issues/<slug>/`
- A single-file spec `specs/issues/<n>-*.md` or `specs/issues/<n>.md` (e.g. from `github-issues-to-md`, `feature-discuss`, `generate-issues`)
- Files in that folder that already cover a role below, even under a different name

If more than one candidate matches, ask which one is right before touching anything.

## Step 2 — Decide the folder

- Existing folder → use it.
- Only a single-file spec exists → create the folder next to it, keep the single file where it is, and link to it as the original issue instead of creating `issue.md`.
- Nothing exists:
  - Known issue number → `specs/issues/<n>-<slug>/`
  - No issue yet → `specs/issues/<slug>/`, and say it should be renamed to `<n>-<slug>` once the issue exists.
  - Sub-issue of `specs/issues/<parent>/` → `specs/issues/<parent>/sub-issues/<n>-<slug>/`
- Slug: short, kebab-case, under 10 words. If no clear name comes from the issue or conversation, propose one and confirm.

Match the language and style of a recent folder under `specs/issues/`.

## Step 3 — Pick only the files this stage needs

| File | Create when | Holds |
|---|---|---|
| **issue.md** | There is an original request and no existing issue file covers it | The original request/issue verbatim (user input or `gh issue view <n>`), a status line, and scope decided so far |
| **investigate.md** | Something was actually investigated | Findings labelled **Confirmed** (cite file:line or log), **Unconfirmed**, or **Cannot confirm** (say what's needed); open questions. Bug: symptom, repro, root cause. Feature: current state, constraints, options considered. |
| **implement.md** | A plan exists | Affected files/modules, concrete steps (by phase if several), order and dependencies, risks. No verification steps. |
| **testcases.md** | Test cases were discussed, or implementation is about to start | Two checklists: **Auto-generatable tests** (unit, mocks, simulated events) and **Tests required on a real device / environment** |
| **report.md** | A report for the leader was finalized in the conversation, or the user asks for the file | The final report as-is. Never draft it here — that's the `report` skill's job. |

For each file:
- **Doesn't exist and is needed** → create it.
- **Already exists** → don't recreate it. Update only the parts the new findings change, and keep everything the user wrote.
- **Not needed yet** → skip it. A later stage (or a later run of this skill) adds it.

## Step 4 — Link the files

- Each file starts with a `## Related` section listing only the other files that **exist** in the set (including an external single-file spec, if that is the original issue).
- When a new file is added to an existing set, add it to the `## Related` section of the files already there.

```
## Related
- [Original issue](./issue.md)
- [Investigation](./investigate.md)
- [Fix direction](./implement.md)
- [Testcases](./testcases.md)
- [Report to leader](./report.md)
```

## Writing rules

- **Short, just enough to act on.** One idea per line, short bullets, steps joined with `→` where natural. Keep steps, observable results, verdicts, decisions. Drop background the code already shows.
- **No duplication.** Each fact lives in one file; other files link to it. Leader-facing wording lives only in report.md.
- **Carry over what was verified, as verified.** Don't upgrade a guess to a fact while summarizing. Keep file:line references out of report.md.
- These rules apply to every later edit too.

## Step 5 — Tell the user

Folder path, then one line per file: created / updated / skipped (and why it was skipped), plus any deviation such as "no issue number yet, rename later".
