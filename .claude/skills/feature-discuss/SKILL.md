---
name: feature-discuss
allowed-tools: Read, Grep, Glob, Bash(find:*), Bash(ls:*), Edit, Write
description: Interactive technical design discussion for a feature before an issue file exists — explores the codebase, surfaces open questions, compares approaches with trade-offs, and gives a recommendation. Only persists to specs/issues/ when the user explicitly finalizes. Use when the user wants to think through a feature or design decision before creating an issue, says "feature-discuss", "thảo luận feature", "bàn thiết kế", or wants to "chốt" a discussion into an issue file.
---

# Feature Discuss

Two modes: **discuss** (default, read-only) and **finalize** (explicit, persists to one file).

## Discuss mode

Triggered by `/feature-discuss <feature-name>`, or whenever the user wants to think through a feature/design decision that has no issue file yet.

1. Explore the codebase read-only for context relevant to the feature: `CLAUDE.md`, existing models/controllers/views for similar features, `specs/ERD.md`, `specs/story.md`, `specs/architecture.md`.
2. Ask what's unclear about requirements — one question at a time, always propose a recommended answer, let the user confirm/override.
3. When multiple viable approaches exist, lay out 2-3 options with trade-offs and give a clear recommendation. This is open-ended architectural judgment, not the structured CRUD/state/soft-delete checklist — that belongs to `drill-issue`, don't duplicate it here.
4. Push back when an assumption looks wrong instead of just agreeing. Iterate conversationally as long as needed.

**Never create or edit anything under `specs/`** in this mode (including `specs/issues/`, `specs/story.md`, `specs/Roadmap.md`) — exploration only.

## Finalize mode

Enter this only on an **explicit** finalize signal:
- `/feature-discuss finalize #<number>`, or
- an unambiguous sentence naming both the decision and an issue number (e.g. "chốt phương án này, issue #12")

A soft "ok sounds good" / "được đó" mid-discussion is NOT a finalize signal — keep discussing. If the signal is ambiguous, confirm first: "Bạn có chắc muốn chốt và ghi vào `specs/issues/<number>-<slug>.md`?" — don't write until confirmed.

### Steps

1. Resolve `<number>` from the signal; derive `<slug>` from the feature name (English, lowercase, spaces → `-`) — same convention `generate-issues` uses.
2. Look for `specs/issues/<number>-<slug>.md`. If a same-numbered file exists under a different slug, confirm with the user it's the right file before touching it.
3. **File doesn't exist** — create it following this project's existing issue format (check a recent file under `specs/issues/` for exact section order): `Status`, `Metadata`, `Description`, `Acceptance Criteria`, `Implementation Checklist`, plus `User Flow`/`Wireframe` (UI features) or `Flow Diagram` (non-UI), and `Key Decisions`. Fill in what the discussion actually produced; leave `Acceptance Criteria`/`Implementation Checklist` skeletal if the discussion didn't cover that depth — `drill-issue`/`generate-issues` own fleshing those out.
4. **File exists** — don't overwrite wholesale. Update only the sections the discussion resolved (e.g. rewrite a paragraph in `Description`, add/replace a bullet in `Key Decisions`) in place. Never touch unrelated sections.
5. Append one line to a `## Decision Log` section at the bottom (create it if missing): `<date>: <one-line decision> — see <section> above`. Never edit or remove prior entries in this log.
6. Report back: file created or updated, and which sections changed.

## Boundaries

- Doesn't run `drill-issue`'s completeness checklist (CRUD/state/soft-delete/association questions) — hand off to `drill-issue` after finalizing if that rigor is still needed.
- Doesn't create GitHub issues directly — that's `write-a-prd` (product-level PRD) or `md-to-github-issues` (sync an existing `specs/issues/` file to GitHub).
- Never checks off or edits `Acceptance Criteria`/`Implementation Checklist` items for work that isn't actually implemented yet.
