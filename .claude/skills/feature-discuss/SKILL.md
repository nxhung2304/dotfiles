---
name: feature-discuss
allowed-tools: Read, Grep, Glob, Bash(find:*), Bash(ls:*), Edit, Write, Skill
description: Interactive technical design discussion for a feature, improvement, or proposal before it's ready to implement — explores the codebase, surfaces open questions, compares approaches with trade-offs, and gives a recommendation. Can save the discussion to specs/issues/ at any time without an issue number (save mode, via issue-docs), and writes the pipeline spec file only on an explicit finalize with an issue number. Use when the user wants to think through a feature or design decision, says "feature-discuss", "thảo luận feature", "bàn thiết kế", "lưu lại thảo luận", or wants to "chốt" a discussion into an issue file.
---

# Feature Discuss

Three modes: **discuss** (default, read-only), **save** (persist the discussion, no issue number needed), and **finalize** (write the pipeline spec file, needs an issue number).

## Discuss mode

Triggered by `/feature-discuss <feature-name>`, or whenever the user wants to think through a feature, improvement, or design decision that isn't ready to implement yet.

1. Explore the codebase read-only for context relevant to the feature: `CLAUDE.md`, existing models/controllers/views for similar features, and project docs such as `specs/ERD.md`, `specs/story.md`, `specs/architecture*.md` — only those that exist.
2. Ask what's unclear about requirements — one question at a time, always propose a recommended answer, let the user confirm/override.
3. When multiple viable approaches exist, lay out 2-3 options with trade-offs and give a clear recommendation. This is open-ended architectural judgment; the structured completeness checklist runs later, before finalize.
4. Push back when an assumption looks wrong instead of just agreeing. Iterate conversationally as long as needed.

**Never create or edit anything under `specs/`** in this mode (including `specs/issues/`, `specs/story.md`, `specs/Roadmap.md`) — exploration only.

## Save mode

Enter on an explicit save request: "lưu lại", "ghi vào specs", "save this", `/feature-discuss save`, or the user wanting to clear the chat and continue later. No issue number needed.

1. Invoke the `issue-docs` skill and hand it what the discussion produced:
   - **investigate.md** ← current state found in the code (Confirmed/Unconfirmed, with file:line), constraints, options considered and why each was kept or dropped, open questions.
   - **implement.md** ← the chosen approach as steps, order, dependencies, risks — only if one was chosen.
   - **testcases.md** ← test cases, only if discussed.
   - **report.md** ← the leader-facing report/estimate, only if one was finalized in the conversation.
2. `issue-docs` picks the folder (`specs/issues/<slug>/` when there's no number yet), creates only the files needed, and reuses existing ones.
3. Saving is not finalizing: don't create the pipeline spec file in this mode.

## Finalize mode

Enter this only on an **explicit** finalize signal:
- `/feature-discuss finalize #<number>`, or
- an unambiguous sentence naming both the decision and an issue number (e.g. "chốt phương án này, issue #12")

A soft "ok sounds good" / "được đó" mid-discussion is NOT a finalize signal — keep discussing. If the signal is ambiguous, confirm first: "Bạn có chắc muốn chốt và ghi vào `specs/issues/<number>-<slug>.md`?" — don't write until confirmed.

### Completeness checklist (run before writing anything)

Explore the codebase first and answer from code whatever it can answer (models/schemas, test data such as fixtures/factories/seeds/mocks, related tests, project conventions file, dependency manifest) — only ask about what code can't determine. Skip any question the discussion already decided.

Ask one question at a time, always with a recommended answer. For each element the feature contains, cover:

- **State / status field (enum, finite set)**: valid values and their integer/string representation; default value and whether it matches the happy-path creation flow; which transitions are automatic (system) vs manual (user/admin); which states are terminal; test data — one variant per non-default state (fixtures/factories/mocks/seeds per stack).
- **Authentication / session**: should non-active statuses block access *(recommend: yes)*; what message/response blocked actors see; overlap with an existing auth mechanism.
- **Soft / logical delete**: does a `deleted`/`archived`/`inactive` state overlap with a soft-delete mechanism or serve a different purpose; can a record be restored after logical delete, and by whom. Adapt to the stack (e.g. Rails `paranoia`/`discard`, Flutter flag field in local DB, Node `deletedAt`).
- **Association / relationship**: on parent delete — restrict, cascade or nullify; nullable or required. Adapt terminology to the stack (foreign keys, embedded documents, nested objects/ID references).
- **Validation / constraint**: which layer — data store, domain/model, API/controller, UI *(recommend: data store + domain as safety net, UI for UX)*; error response on failure.
- **CRUD / resource actions** — for every action:
  - List/Index: scoped to the current actor or global; filtering/search/sorting fields; pagination and default page size.
  - Read/Show: any authenticated actor, or only owned/related records.
  - Create: who may create (any authenticated actor, role, system only); uniqueness rules beyond a data-store index; initial state.
  - Update: own vs others' records; fields immutable after creation; blank credential/secret field on update — cleared or ignored *(recommend: ignore blank)*.
  - Delete: hard, logical or soft; self-delete *(recommend: block — treat as a distinct flow with confirmation, sign-out, notification)*; can a lower-privilege actor delete a higher-privilege one; what happens to child records (cascade, restrict, nullify).
  - Per mutation action: is there any actor who should be blocked even though they pass the basic auth check.
- **Actor acting on their own record**: for every action that targets a resource by ID, what happens when the ID resolves to the current actor's own record; flag self-targeting that is unexpected, dangerous or nonsensical.

Then check for contradictions and surface the most important one first as *"X says A but Y implies B — which is correct?"*:
- persistence default ≠ test data default with no documented reason
- state values inconsistent with project convention
- validation at domain layer with no data-store constraint (or vice versa)
- state transitions that don't match the stated business rules
- delete behavior (hard/logical/soft) inconsistent with an existing state field or soft-delete mechanism

The answers feed the spec written below: every decision with its rationale → `Key Decisions`; confirmed behavior → `Flow Diagram` (state transitions or request/action flow); test-data variants for all confirmed states → snippets; gotchas, deferred decisions, dependency gaps → notes. Status, Metadata and GitHub Issue number stay untouched.

### Steps

1. Resolve `<number>` from the signal; derive `<slug>` from the feature name (English, lowercase, spaces → `-`) — same convention `generate-issues` uses.
2. Look for `specs/issues/<number>-<slug>.md`. If a same-numbered file exists under a different slug, confirm with the user it's the right file before touching it.
3. **File doesn't exist** — create it following this project's existing issue format (check a recent file under `specs/issues/` for exact section order): `Status`, `Metadata`, `Description`, `Acceptance Criteria`, `Implementation Checklist`, plus `User Flow`/`Wireframe` (UI features) or `Flow Diagram` (non-UI), and `Key Decisions`. Fill in what the discussion actually produced; leave `Acceptance Criteria`/`Implementation Checklist` skeletal if the discussion didn't cover that depth — `generate-issues` owns fleshing those out.
4. **File exists** — don't overwrite wholesale. Update only the sections the discussion resolved (e.g. rewrite a paragraph in `Description`, add/replace a bullet in `Key Decisions`) in place. Never touch unrelated sections.
5. Append one line to a `## Decision Log` section at the bottom (create it if missing): `<date>: <one-line decision> — see <section> above`. Never edit or remove prior entries in this log.
6. **A saved folder exists** for this work (from save mode, e.g. `specs/issues/<slug>/`):
   - Rename it to `specs/issues/<number>-<slug>/`.
   - Add a link to the folder in the spec file (under `Key Decisions` or a `Related` line), and invoke `issue-docs` to link the folder's files back to the spec file as the original issue.
   - Keep the spec file to what to build; leave findings and rejected options in the folder and link to them instead of copying.
7. Report back: file created or updated, which sections changed, and whether a saved folder was renamed and linked.

## Boundaries

- Doesn't create GitHub issues directly — use `md-to-github-issues` to sync an existing `specs/issues/` file to GitHub.
- Never checks off or edits `Acceptance Criteria`/`Implementation Checklist` items for work that isn't actually implemented yet.
- Doesn't write the leader report itself — use `report` for that, then save it via save mode.
