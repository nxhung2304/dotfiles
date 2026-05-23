# Skills Catalog

## Project Skills

### 📋 Git & Commit Management

| Skill | Description |
| :--- | :--- |
| **[commit](./commit/SKILL.md)** | Create professional git commits with bullet-point messages and Co-Authored-By footer. Reads staged changes, formats with type prefix (feat/fix/refactor), and commits automatically. |
| **[commit-push](./commit-push/SKILL.md)** | Commit staged changes and push to remote. Uses `commit` skill then pushes to remote branch. |

### 📝 Issue & Spec Management

| Skill | Description |
| :--- | :--- |
| **[write-a-prd](./write-a-prd/SKILL.md)** | Create PRD through user interview, codebase exploration, and module design. Identifies durable architectural patterns and submits as GitHub issue. |
| **[github-issues-to-md](./github-issues-to-md/SKILL.md)** | Fetch GitHub Issues and save locally as Markdown in `specs/issues/[number].md`. Converts issues for local management and review. |
| **[drill-issue](./drill-issue/SKILL.md)** | Deep dive into issue content through systematic questioning. Clarifies requirements, constraints, edge cases until crystal-clear. Generates implementation checklist as output. |
| **[md-to-github-issues](./md-to-github-issues/SKILL.md)** | Sync approved local issue files from `specs/issues/` to GitHub Issues. Updates issue numbers in local files automatically. |
| **[generate-issues](./generate-issues/SKILL.md)** | Create individual issue files from `specs/story.md` tasks. Generates `specs/issues/[number]-[slug].md` files with implementation guides. |

### 📐 Planning & Design

| Skill | Description |
| :--- | :--- |
| **[prd-to-story](./prd-to-story/SKILL.md)** | Transform PRD into PR-sized tasks. Breaks into phased plan using tracer-bullet vertical slices, then groups into concrete tasks. Outputs `specs/story.md` with implementation checklist. |

### 🔍 Review & Quality

| Skill | Description |
| :--- | :--- |
| **[review-specs](./review-specs/SKILL.md)** | Review specifications for completeness and clarity. Analyzes acceptance criteria, checklists, design refs, and edge cases. Saves feedback to `specs/comments/[ISSUE-NUMBER]-spec-review.md`. |
| **[review-branch](./review-branch/SKILL.md)** | Review code against project rules (core.md, code-rules/, specs/rules/). Generates actionable feedback in `specs/comments/[ISSUE-NUMBER]-code-review.md`. |

### 🚀 Implementation Pipeline

Complete automated workflow for implementing issues from spec to merged PR:

| Skill | Description |
| :--- | :--- |
| **[implement-issue](./implement-issue/SKILL.md)** | **Orchestrator** - Coordinates full issue implementation: prepare → code → quality → finalize. Main entry point for spec implementation. Runs sequentially without stopping. |
| **[implement-prepare](./implement-prepare/SKILL.md)** | Prepares environment: checkout develop, pull latest, create feature branch, validate approval, notify Slack. Returns branch info and thread ID. |
| **[implement-code](./implement-code/SKILL.md)** | Execute Implementation Checklist items sequentially. Calls rule-lookup before each item, design-checker for UI changes, code-reviewer for verification. |
| **[implement-quality](./implement-quality/SKILL.md)** | Run project-specific quality checks (flutter/rubocop/npm/pytest/cargo). Auto-fixes issues via error-fixer subagent. Verifies zero warnings. |
| **[implement-finalize](./implement-finalize/SKILL.md)** | Commit changes, update spec status, push branch, create draft PR, notify Slack completion. Returns PR URL and committed files. |

## System Skills (Internal)

| Skill | Description |
| :--- | :--- |
| **[imagegen](./.system/imagegen/SKILL.md)** | Generate or edit raster images using AI models. |
| **[openai-docs](./.system/openai-docs/SKILL.md)** | Provide authoritative guidance and model migration info from OpenAI documentation. |
| **[plugin-creator](./.system/plugin-creator/SKILL.md)** | Scaffold new plugin directories and marketplace entries for the agent. |
| **[skill-creator](./.system/skill-creator/SKILL.md)** | Expert guidance and templates for creating or updating skills. |
| **[skill-installer](./.system/skill-installer/SKILL.md)** | Tooling to install new skills from curated lists or remote repositories. |
