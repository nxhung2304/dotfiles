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
| Description | ✓ | 2–4 lines, context only, không lặp checklist |
| Acceptance Criteria | ✓ | checkbox list, testable |
| Implementation Checklist | ✓ | checkbox list, actionable steps |
| User Flow | UI features only | navigation tree, stack-agnostic |
| Wireframe | UI features only | ASCII mockup màn hình chính |
| Flow Diagram | Non-UI features | request/response, state machine, data flow |
| Key Decisions | ✓ | bullet list, chỉ những gì không hiển nhiên |

---

### 5. User Flow *(UI features only)*

Cây ASCII thể hiện luồng điều hướng — dùng tên thực tế của project, không dùng notation của bất kỳ framework cụ thể nào.

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

Bỏ qua section này nếu feature không có user-facing screen (jobs, migrations, API-only).

---

### 6. Wireframe *(UI features only)*

ASCII mockup, chỉ các màn hình chính. Không cần modal/toast/edge case UI.

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

Dùng khi feature không có screen (API endpoint, background job, migration, webhook...).

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
Chỉ ghi những gì không hiển nhiên:
- Tại sao chọn approach này thay vì alternative (nested vs standalone, polling vs webhook, v.v.)
- Constraint kỹ thuật quan trọng (library limitation, DB restriction, API rate limit)
- Không lặp lại những gì đã rõ trong checklist

---

### 9. KHÔNG đưa vào issue
- "Files to create/modify" list — trùng với checklist
- Skeleton code với empty body (signature + empty body không thêm giá trị gì)
- Empty test stubs (test name không có nội dung)
- Snippets cho code hiển nhiên (3-line route, 1-line config)
- Chỉ thêm snippet khi cú pháp thực sự non-obvious hoặc dễ sai — và phải có nội dung thực, không để trống

---

### 10. Output
Summary: số issue tạo được + next steps.

**Rules:** Status always `pending` — dev changes to `approved` manually.
