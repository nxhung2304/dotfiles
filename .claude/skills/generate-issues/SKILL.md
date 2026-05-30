---
name: generate-issues
allowed-tools: Grep, Bash(touch:*), Bash(mkdir -p *), Bash(cat:*), Bash(ls:*), Bash(find:*), Read, Edit, Write
description: Create issues from specs/story.md. Use when user asks "Generate issues, generate issue [number].[title]"
---

Read `specs/story.md` → Parse tasks → Create individual issue files in `specs/issues/`

**Steps:**
0. **Check the project before generating:**
   - Read `CLAUDE.md` or `README.md` for project context (if available)
   - Detect tech stack: `Gemfile`, `package.json`, `pubspec.yaml`, `go.mod`, etc.
   - Inspect existing folder structure (`app/`, `src/`, `lib/`, `test/`, etc.)
   - Infer conventions from existing files (naming, folder structure, test framework)
   - Use this context to fill in accurate file paths, tool/gem names, and test commands in the issues

1. Read `specs/story.md`, parse tasks: `- [ ] [number]. [title]`
2. **If ARGUMENTS are provided**, use them to filter:
   - If args mention a specific issue number (e.g. `1`, `1.1`) → generate only that issue
   - If args contain extra spec details (e.g. column definitions, enum values) → treat them as additional context/overrides for the matched issue only
   - Do NOT generate all issues when args are scoped to a specific task
3. `mkdir -p specs/issues`
4. For each task (or the single filtered task) → create file `specs/issues/[number]-[slug-title].md`
   - Slug: English, lowercase, spaces → `-`
   - Skip if the file already exists
4. Content follows `template.md`
5. **Step-by-step Guide**: Write enough for an AI agent or human to implement without asking follow-up questions:
   - File paths to create/modify
   - Key decisions/constraints (e.g. "validate at the model layer, not the controller", "use a join table, not a JSON column")
   - Code snippets for every non-obvious part (model callbacks, validations, query scopes, controller filters) using **skeleton style**:
     - One-line comment above the method describing what it does
     - Method signature + empty body — NO numbered steps, NO implementation inside
     - Test stubs: `test "description" do` with empty body
6. **Flow Diagram**: Always include an ASCII diagram in the Step-by-step Guide that shows:
   - For models: state machine / enum transitions (e.g. `draft → reviewing → published`)
   - For controllers/API: request → auth check → business logic → response flow
   - For multi-model features: data relationship and write path
   - For UI features: user action → component → server → render cycle
   - Use `→` for flow, `|` for branches, boxes for states/actors. Keep it under 20 lines.
7. Output a summary with count + next steps

**Rules:** Status is always `pending` — the dev changes it to `approved` manually
