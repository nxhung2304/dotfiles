---
name: prd-to-story
description: Transform PRD into PR-sized tasks using tracer-bullet vertical slices. Creates phased implementation plan then groups into concrete tasks. Outputs specs/story.md with implementation checklist.
---

# PRD to Story

> **Shortcut skill** — combines `prd-to-plan` + `plan-to-story` in one pass. Use for small/medium features where you don't need to persist the intermediate plan file. For large features or when you want to review/adjust the plan before tasking, run `prd-to-plan` → `plan-to-story` separately. Output goes to `specs/story.md` directly (no `plans/` file created).

Transform a PRD into concrete, PR-sized implementation tasks in one unified workflow.

## What this skill does

Takes a PRD and generates `specs/story.md` with:
- **Phased breakdown**: Tracer-bullet vertical slices (each phase is complete end-to-end)
- **PR-sized tasks**: Grouped acceptance criteria per task (not per phase)
- **Implementation checklist**: Actionable items for developers
- **Durable decisions**: Architectural patterns that guide implementation

## Input

The PRD should already be in context. If not, ask user to paste it or point to the file.

## Process

### 1. Explore codebase (if needed)

Understand current architecture, patterns, and integration layers to inform slicing decisions.

### 2. Identify durable architectural decisions

Before slicing, identify high-level decisions unlikely to change:
- Route structures / URL patterns
- Database schema shape
- Key data models
- Authentication / authorization approach
- Third-party service boundaries

These go in the plan header for reference throughout implementation.

### 3. Break PRD into tracer-bullet phases

Identify logical phases that deliver narrow but COMPLETE end-to-end value:
- Each phase cuts through ALL layers (schema, API, UI, tests) - NOT horizontal slices
- A completed phase is demoable or verifiable on its own
- Prefer many thin phases over few thick ones
- Focus on durable decisions (routes, schema, models), NOT implementation details

### 4. Quiz the user on phase breakdown

Present phases with:
- **Title**: short name
- **User stories covered**: which PRD user stories this addresses

Ask:
- Does granularity feel right? (too coarse / too fine)
- Should phases be merged or split?

Iterate until approved.

### 5. Group phases into PR-sized tasks

For each phase, identify logical task groupings:
- Each task should be ~40–100 lines of code (single PR)
- Deliver end-to-end functionality (not just one layer)
- Related criteria belong together (e.g., "form validation + submission")
- Aim for 3–8 acceptance criteria per task

Task naming should describe outcome: "Setup form + validation + submission" not "Create component"

### 6. Write story.md

Create `specs/story.md` with structure:

```markdown
## Phase N: <Title>

### Task N.1: <Task title>
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
- [ ] Acceptance criterion 3

### Task N.2: <Task title>
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

### 7. Add metadata section

At end of story.md:
- Total task count
- Summary of phases
- Instructions for checking off items
- Progress tracking checklist (one per phase)

## Example

**Input (PRD excerpt):**
```
## User Stories
1. As a user, I want to create an account
2. As a user, I want to log in with email/password
3. As a user, I want to see my profile
```

**Output (story.md excerpt):**
```
## Phase 1: Authentication Foundation

### Task 1.1: User schema & auth setup
- [ ] Create users table with email/password fields
- [ ] Setup authentication middleware
- [ ] Create signup endpoint

### Task 1.2: Auth UI components
- [ ] Build login form
- [ ] Build signup form
- [ ] Add password validation

## Phase 2: User Profile

### Task 2.1: Profile page
- [ ] Create profile route
- [ ] Display user info
- [ ] Add edit profile functionality
```

## Tips

- **Grouping heuristic**: Criteria should be functionally related
- **Naming**: Describe outcome, not implementation ("About page - bio & timeline" not "Create component")
- **Sizing**: 3–8 criteria per task (not 1–2, not 15+)
- **Vertical slices**: Each task touches multiple layers (UI + backend + database)
- **Sequential order**: Tasks within story.md are implementation order

## Notes

- Tasks numbered sequentially within phase (1.1, 1.2, etc.)
- Story.md is authoritative source for implementation
- Mark items [ ] → [x] as you complete (git-friendly)
- Each completed task = one mergeable PR
