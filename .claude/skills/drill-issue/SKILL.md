---
name: drill-issue
description: Deep dive into issue content through systematic questioning. Clarifies requirements, constraints, and edge cases until you have clear understanding. Generates implementation checklist as output.
---

# Drill Issue

Systematically clarify issue requirements through targeted questioning until requirements are unambiguous. Writes decisions back to the issue file when done.

## What this skill does

- **Reads the issue file** and existing codebase context
- **Asks targeted questions** — generic + domain-specific based on what the issue contains
- **Resolves contradictions** before implementation starts
- **Writes clarified decisions back** into the issue file (Key decisions, Notes, flow diagram)

## Process

### 1. Read & explore first

Read the issue file, then explore the codebase to answer what can be answered without asking:
- Existing models/entities/schemas, test data (fixtures/factories/seeds/mocks), and tests related to this issue
- Project conventions file (`CLAUDE.md`, `CONTRIBUTING.md`, `README.md`, etc.)
- Dependency manifest (`Gemfile`, `package.json`, `pubspec.yaml`, `go.mod`, `requirements.txt`, `Cargo.toml`, etc.)

If a question can be answered by reading the codebase — read the codebase instead of asking.
Only ask the user about things that cannot be determined from code.

### 2. Build the decision tree

Map out every decision this issue requires before asking anything. Order them by dependency — a decision that others depend on comes first. Example:

```
state/enum design
  └── default value
        └── test fixture/factory defaults
              └── fixture variants needed for tests
```

### 3. Interview one question at a time

Work down the decision tree one branch at a time:
- Ask **one question at a time** — never a list
- Always provide your **recommended answer** with reasoning — the user confirms, adjusts, or overrides
- When the user answers, resolve dependent decisions that are now unblocked before moving to the next branch
- If an answer reveals a new gap or contradiction, follow up on it immediately before continuing

#### Trigger-based questions — include these when the issue contains the element

**State / status field (enum, finite set of values)?**
- What are the valid values and their integer/string representation?
- What is the default value? Does it match the happy-path creation flow?
- Which transitions are automatic (system-triggered) vs manual (user/admin action)?
- Which states are terminal (no further transitions allowed)?
- Test data: one variant per non-default state — list every state the tests will need (fixtures/factories/mocks/seeds depending on stack)

**Authentication / session (any auth system)?**
- Should non-active statuses block access? *(recommend: yes)*
- What message or response should blocked actors see?
- Does this overlap with an existing auth mechanism already in place?

**Soft / logical delete (any language/framework)?**
- Does a `deleted` / `archived` / `inactive` state overlap with a soft-delete mechanism, or do they serve different purposes?
- After logical delete, can the record be restored? By whom?
- Framework note: Rails → `paranoia`/`discard`; Flutter → flag field in local DB; Node → `deletedAt` timestamp pattern

**Association / relationship (foreign key, join table, embedded, reference)?**
- On parent delete: restrict (block deletion), cascade (delete children), or nullify (clear reference)?
- Is the relationship nullable or required?
- Framework note: adapt terminology — Rails uses foreign keys; MongoDB uses embedded documents; Flutter/Dart uses nested objects or ID references

**Validation / constraint?**
- At which layer: data store, domain/model, API/controller, or UI? *(recommend: data store + domain as safety net, UI for UX)*
- What is the error response when validation fails?

**CRUD / resource actions present?**

For **every action**, systematically ask:

- **List / Index:**
  - Is the list scoped to the current actor (own records only) or global (all records)?
  - Is filtering, search, or sorting required? If so, which fields?
  - Is pagination required? What is the default page size?

- **Read / Show:**
  - Can any authenticated actor view any record, or only records they own / are related to?

- **Create:**
  - Who is allowed to create (any authenticated actor, specific role, system only)?
  - Are there uniqueness rules beyond a data-store index?
  - What is the initial state of the new record?

- **Update:**
  - Can an actor update their own record? Can they update others' records?
  - Are any fields immutable after creation (e.g. identifier, email after verification)?
  - If a credential/secret field (password, token) is left blank on update, should it be cleared or ignored? *(recommend: ignore blank)*

- **Delete / Remove:**
  - Is delete hard (row removed), logical (status/flag change), or soft (timestamp set)?
  - Can an actor delete their own record / act on themselves? *(recommend: block self-delete — treat it as a distinct flow with confirmation, sign-out, notification)*
  - Can a lower-privilege actor delete a higher-privilege one?
  - What happens to associated/child records on delete (cascade, restrict, nullify)?

- **Per-action actor restrictions:**
  - For each mutation action, explicitly ask: "Is there any actor who should be blocked even though they pass the basic auth check?"

**Actor acting on their own record?**
- For every action that targets a resource by ID, ask: what happens when that ID resolves to the current actor's own record?
- Flag any action where self-targeting produces unexpected, dangerous, or nonsensical behavior.

### 4. Detect and resolve contradictions

Watch for these automatically:
- Data-store/persistence default ≠ test data default with no documented reason
- State values inconsistent with project convention
- Validation at domain layer but no data-store constraint (or vice versa)
- State transitions in the spec that don't match the stated business rules
- Delete behavior (hard/logical/soft) inconsistent with existing state field or soft-delete mechanism

Surface contradictions directly: *"X says A but Y implies B — which is correct?"* — then ask the single most important one first.

### 5. Write decisions back to the issue file

After all questions are resolved, update the issue file:
- **Key decisions** — every decision made, with its rationale
- **Flow diagram** — ASCII state transitions or request/action flow matching confirmed behaviour
- **Snippets** — test data variants skeleton updated with all confirmed states (use the project's convention: fixtures/factories/mocks/seeds)
- **Notes** — gotchas, deferred decisions, dependency gaps

Do not change Status, Metadata, or GitHub Issue number.

### 6. Output summary

- **Decisions made** — bullet list
- **Sections updated in the issue file**
- **Next step** — ready to implement, or flag if another round is needed

## Rules

- One question at a time — always
- Always recommend an answer — never ask cold
- Explore the codebase before asking — don't ask what the code already answers
- Write decisions back to the issue file — the chat is not the output
- Flag contradictions directly and resolve them before moving on
