---
name: generate-issues
allowed-tools: Grep, Bash(touch:*), Bash(mkdir -p *), Bash(cat:*), Bash(ls:*), Bash(find:*), Read, Edit, Write
description: Create issues from specs/story.md. Use when user asks "Generate issues, generate issue [number].[title]"
---

Read `story.md` → Parse tasks → Create individual issue files in `issues/`

**Steps:**

### 0. Detect project layout
- Read `CLAUDE.md` or `README.md` for project context
- Detect tech stack: `Gemfile`, `package.json`, `pubspec.yaml`, `go.mod`, `requirements.txt`, etc.
- Inspect folder structure (`app/`, `src/`, `lib/`, `test/`, `screens/`, etc.)
- Infer conventions from existing files (naming, test framework, routing style)
- **Find story.md**: check `specs/story.md` → `story.md` → search project root. Use whichever exists.
- **Issues folder**: sibling of story.md → `issues/` subfolder (e.g. `specs/issues/` or `issues/`)

### 1. Parse tasks
Read story.md, parse: `- [ ] [number]. [title]`

### 2. Filter by arguments (if provided)
- Specific number (e.g. `1`, `1.1`) → generate only that issue
- Extra spec details → treat as additional context/overrides for that issue only
- Do NOT generate all issues when args are scoped to a specific task

### 3. Create files
- `mkdir -p <issues-folder>`
- File: `<issues-folder>/[number]-[slug].md` — slug: English, lowercase, spaces → `-`
- Skip if file already exists

### 4. Issue structure
Every issue contains these sections in order:

| Section | Always? | Notes |
|---|---|---|
| Status + Metadata | ✓ | title, phase, issue tracker link (if any) |
| Description | ✓ | 2–4 lines, context only, don't repeat the checklist |
| Acceptance Criteria | ✓ | checkbox list, testable |
| Implementation Checklist | ✓ | checkbox list, actionable steps |
| User Flow | UI features only | navigation tree, stack-agnostic |
| Wireframe | UI features only | ASCII mockup of the main screens |
| Flow Diagram | Non-UI features | request/response, state machine, data flow |
| Key Decisions | ✓ | bullet list, only what's non-obvious |

---

### 5. User Flow *(UI features only)*

An ASCII tree showing the navigation flow — use the project's actual names, not the notation of any specific framework.

**Web (MVC/SPA):**
```
Course List
    └── Course Detail
            └── Sections  ──────────────────────────┐
                    ├── [New]   → New Form → Detail  │
                    ├── [Edit]  → Edit Form → Detail │
                    └── [Delete]→ Sections ──────────┘
```

**Mobile (Flutter/React Native):**
```
HomeScreen
    └── CourseDetailScreen
            └── SectionListScreen
                    ├── → NewSectionScreen → SectionDetailScreen
                    └── → EditSectionScreen → SectionDetailScreen
```

**CLI:**
```
myapp
    ├── course list
    ├── course create <name>
    └── section
            ├── section list --course <id>
            └── section add --course <id> <title>
```

Skip this section if the feature has no user-facing screen (jobs, migrations, API-only).

---

### 6. Wireframe *(UI features only)*

ASCII mockup, main screens only. No need for modal/toast/edge-case UI.

**Web:**
```
Sections  (/courses/:id/sections)         [+ New]
──────────────────────────────────────────────────
[Search by title...]  [Search]

  Title                 Position   Actions
  ────────────────────────────────────────
  Introduction          1          View · Edit · Delete
  Setup                 2          View · Edit · Delete

  < 1 2 3 >
```

**Mobile:**
```
┌─────────────────────┐
│ ← Sections          │
│─────────────────────│
│ 🔍 Search...        │
│─────────────────────│
│ Introduction      > │
│ Setup             > │
│ Core Concepts     > │
│─────────────────────│
│      [+ Add]        │
└─────────────────────┘
```

---

### 7. Flow Diagram *(non-UI features)*

Use when the feature has no screen (API endpoint, background job, migration, webhook...).

**API endpoint:**
```
POST /api/sections
    → authenticate (JWT/session)
    → authorize (owns course?)
    → validate params
    → create Section
    → return 201 / 422
```

**Background job:**
```
Trigger (cron / event)
    → load records
    → process each
        ├── success → update status
        └── error   → retry queue → dead letter
```

**State machine:**
```
draft → published → archived
  │                    ↑
  └──── rejected ──────┘
```

---

### 8. Key Decisions
Only record what's non-obvious:
- Why this approach was chosen over an alternative (nested vs standalone, polling vs webhook, etc.)
- Important technical constraints (library limitation, DB restriction, API rate limit)
- Don't repeat what's already clear from the checklist

---

### 9. Do NOT include in the issue
- A "Files to create/modify" list — duplicates the checklist
- Skeleton code with an empty body (signature + empty body adds no value)
- Empty test stubs (test name with no content)
- Snippets for obvious code (a 3-line route, a 1-line config)
- Only add a snippet when the syntax is genuinely non-obvious or error-prone — and it must have real content, never left blank

---

### 10. Output
Summary: number of issues created + next steps.

**Rules:** Status always `pending` — dev changes to `approved` manually.
