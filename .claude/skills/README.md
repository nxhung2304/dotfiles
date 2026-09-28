# Skills Catalog

## Project Skills

### 📋 Git & Commit Management

| Skill | Usage | Description |
| :--- | :--- | :--- |
| **[commit](./commit/SKILL.md)** | `/commit` (no args) | Reads staged changes, generates a `type: subject` commit message + WHAT/WHY bullets, **commits immediately, no confirmation**. |
| **[short-commit](./short-commit/SKILL.md)** | `/short-commit` | Shows a single one-line commit message summarizing staged changes; **only commits after the user approves it**. |
| **[commit-push](./commit-push/SKILL.md)** | `/commit-push` | Calls `commit` → `git push` → reports commit hash + push result. |
| **[commit-push-by-category](./commit-push-by-category/SKILL.md)** | `/commit-push-by-category` | Groups changed files by logical category (directory/file type), commits each group separately via `commit`, then pushes via `commit-push`. |
| **[pr-desc](./pr-desc/SKILL.md)** | `/pr-desc` or `/pr-desc lang: en` | Summarizes the diff/commit log between the current branch and base into a PR description (prints only, **does not create/update the PR on GitHub**). Defaults to Vietnamese. |

### 📝 Issue & Spec Management

| Skill | Usage | Description |
| :--- | :--- | :--- |
| **[github-issues-to-md](./github-issues-to-md/SKILL.md)** | needs `owner`, `repo`, `issue_number` | Fetches a GitHub Issue via MCP, converts to Markdown, saves as `specs/issues/[issue-number].md`. |
| **[feature-discuss](./feature-discuss/SKILL.md)** | `/feature-discuss <feature-name>` | `discuss` mode (default, read-only): design discussion before an issue file exists. `finalize` mode: only on an explicit signal (`/feature-discuss finalize #<number>` or an unambiguous confirming sentence) does it write to `specs/issues/`. |
| **[drill-issue](./drill-issue/SKILL.md)** | point it at an issue file | Asks one question at a time to clarify requirements/edge cases, writes decisions back into the issue file (Key decisions, Notes). |
| **[grill-me](./grill-me/SKILL.md)** | `grill-me` | Interviews the user relentlessly about a plan/design until every decision branch is resolved (up to ~15 questions), ends with a Decision Summary. |
| **[fix-issue](./fix-issue/SKILL.md)** | `/fix-issue` or state the issue number/bug description | Phase 1: investigates the bug via Q&A + code tracing, produces a root cause + fix plan. Only scaffolds the 5 files (`issue.md`, `investigate.md`, `implement.md`, `testcases.md`, `report.md`) under `specs/issues/` once the user confirms they're starting a real fix. |
| **[bug-report-writer](./bug-report-writer/SKILL.md)** | paste/write a bug report draft then invoke the skill | Rewrites/refines a bug investigation report before sending to a leader/reviewer; section count scales with severity. |
| **[md-to-github-issues](./md-to-github-issues/SKILL.md)** | `/md-to-github-issues` (no args) | Syncs files under `specs/issues/*.md` that are `Review: Approved` and have no `GitHub Issue: #` yet up to GitHub Issues, writes the issue number back into the file. |
| **[generate-issues](./generate-issues/SKILL.md)** | `/generate-issues` or `/generate-issues 1.1` | Reads `specs/story.md`, parses `- [ ] [number]. [title]` tasks, creates individual issue files in `issues/` (can target a specific number). |

### 🔍 Review & Quality

| Skill | Usage | Description |
| :--- | :--- | :--- |
| **[review-specs](./review-specs/SKILL.md)** | `/review-specs #11` or state the issue number | Reviews the spec in `specs/issues/[issue-number]` (Acceptance Criteria, Checklist, edge cases...), writes feedback to `specs/comments/[ISSUE-NUMBER]-spec-review.md`. |
| **[review-branch](./review-branch/SKILL.md)** | `/review-branch` or `/review-branch feature/auth main` or `/review-branch include-staged: true` | Reviews against project clean-code/style/security/performance rules. Default diffs branch-vs-base only (committed); `include-staged: true` also reviews staged changes. Writes `specs/comments/[branch]-title.md`. |
| **[review-issue](./review-issue/SKILL.md)** | `/review-issue` | **Orchestrator** — runs `review-branch` (with `include-staged: true`) + the built-in `code-review` skill in parallel, merges/dedupes findings, maps severity to MUST/SHOULD/NIT, writes `specs/issues/<issue-number>/comment.log`. Never fixes code or comments on the PR. |

### 🚀 Implementation Pipeline

Complete automated workflow for implementing issues from spec to merged PR:

| Skill | Usage | Description |
| :--- | :--- | :--- |
| **[implement-issue](./implement-issue/SKILL.md)** | `/implement-issue <spec-filename>` | **Orchestrator** — coordinates full issue implementation: prepare → code → quality → finalize. Main entry point for spec implementation. Runs sequentially without stopping. |
| **[implement-local](./implement-local/SKILL.md)** | `/implement-local <spec-filename>` | Same as `implement-issue` but stops after the quality check — no commit, no PR, no Slack notification. |
| **[implement-prepare](./implement-prepare/SKILL.md)** | used internally by the two above | Checks out + pulls `develop`/`main`, verifies `Review: Approved`, creates branch `feature/[user]-#[issue]-[slug]`, notifies Slack if configured. |
| **[implement-code](./implement-code/SKILL.md)** | used internally | Reads the spec's Implementation Checklist, codes each item, calls `rule-lookup`/`design-checker`/`code-reviewer` as needed. |
| **[implement-quality](./implement-quality/SKILL.md)** | used internally | Auto-detects the stack (Flutter/Rails/Go/Rust/Python/Node...) and runs the matching checks (`flutter analyze`, `rubocop`, ...), calls `error-fixer` on errors. |
| **[implement-finalize](./implement-finalize/SKILL.md)** | used internally | Commits, updates spec status → `PR: Draft`, pushes, opens a Draft PR via GitHub MCP, notifies Slack. |

---

## Which skill should I use?

| I want to... | Use |
| :--- | :--- |
| Turn a rough idea into a design decision before an issue exists | `feature-discuss` |
| Clarify requirements/edge cases on an existing issue file | `drill-issue` |
| Stress-test my own plan by getting interrogated about it | `grill-me` |
| Investigate a reported bug and find the root cause | `fix-issue` |
| Write/polish a bug report before sending it to a leader | `bug-report-writer` |
| Turn `specs/story.md` tasks into individual issue files | `generate-issues` |
| Pull a GitHub Issue into a local spec file, or push local specs to GitHub | `github-issues-to-md` / `md-to-github-issues` |
| Sanity-check a spec before implementation starts | `review-specs` |
| Implement an approved spec end-to-end (branch → code → tests → PR) | `implement-issue` |
| Implement locally without touching git/PR/Slack yet | `implement-local` |
| Review a branch/diff against project rules | `review-branch` |
| Get a merged, translated MUST/SHOULD/NIT review before opening a PR | `review-issue` |
| Commit staged changes | `commit` (auto) or `short-commit` (asks approval first) |
| Commit and push in one go | `commit-push` |
| Commit multiple unrelated changes as separate, well-scoped commits | `commit-push-by-category` |
| Write a plain-language PR description from the diff | `pr-desc` |

## Common Workflows

**New feature, from idea to PR:**
```
feature-discuss <name>          # discuss design, finalize → writes specs/issues/<n>.md
  → drill-issue                 # clarify remaining edge cases
  → implement-issue <spec>       # prepare → code → quality → finalize (branch, commit, draft PR)
  → review-issue                 # merged review before requesting human review
  → (fix any MUST/SHOULD findings, re-run review-issue if needed)
```

**Bug fix:**
```
fix-issue                        # investigate, root cause, fix plan
  → (user confirms) scaffolds specs/issues/<n>/{issue,investigate,implement,testcases,report}.md
  → implement-local or manual fix
  → review-branch include-staged: true   # review before committing
  → commit-push
  → bug-report-writer              # if a report needs to go to a leader/reviewer
```

**Story → GitHub, spec-driven:**
```
generate-issues                  # specs/story.md → specs/issues/*.md
  → review-specs #N              # sanity-check before approval
  → (Review: Approved) md-to-github-issues   # push to GitHub, get issue number back
  → implement-issue <spec>
```

**Pre-PR safety net on an already-coded branch:**
```
review-issue                     # review-branch + code-review merged, MUST/SHOULD/NIT
  → fix findings manually
  → pr-desc                      # write the PR description
  → commit-push
```
