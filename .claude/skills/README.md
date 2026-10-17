# Skills Catalog

## Project Skills

### 📋 Git & Commit Management

| Skill | Usage | Description |
| :--- | :--- | :--- |
| **[commit](./commit/SKILL.md)** | `/commit` (no args), or params `format=short\|full auto=true\|false push=true\|false footer=true\|false` | Reads staged changes and commits. No args = `format=full auto=true`: `type: subject` + WHAT/WHY bullets, **commits immediately, no confirmation**. `format=short` = single oneline message; `auto=false` = **only commits after the user approves the message**; `push=true` = also `git push` and report the result; `footer=true` = append the `Co-Authored-By:` trailer. Replaces the old `short-commit` (`format=short auto=false`) and `commit-push` (`push=true`). |
| **[commit-push-by-category](./commit-push-by-category/SKILL.md)** | `/commit-push-by-category` | Groups changed files by logical category (directory/file type), commits each group separately via `commit`, pushing with the last commit (`push=true`). Manual-only (`disable-model-invocation`). |
| **[pr-desc](./pr-desc/SKILL.md)** | `/pr-desc` or `/pr-desc lang: en` | Summarizes the diff/commit log between the current branch and base into a PR description (prints only, **does not create/update the PR on GitHub**). Defaults to Vietnamese. |

### 📝 Issue & Spec Management

| Skill | Usage | Description |
| :--- | :--- | :--- |
| **[github-issues-to-md](./github-issues-to-md/SKILL.md)** | needs `owner`, `repo`, `issue_number` | Fetches a GitHub Issue via MCP, converts to Markdown, saves as `specs/issues/[issue-number].md`. |
| **[feature-discuss](./feature-discuss/SKILL.md)** | `/feature-discuss <feature-name>`, `/feature-discuss save`, `/feature-discuss finalize #<number>` | `discuss` (default, read-only): design discussion for a feature/improvement/proposal. `save`: persists the discussion via `issue-docs`, no issue number needed. `finalize`: on an explicit signal with an issue number, writes the pipeline spec file `specs/issues/<n>-<slug>.md` and links it to the saved folder. Before writing, `finalize` runs a trigger-based completeness checklist (state/auth/soft-delete/association/validation/CRUD/self-targeting questions + contradiction check) and writes the decisions into the spec. |
| **[fix-issue](./fix-issue/SKILL.md)** | `/fix-issue` or state the issue number/bug description | Phase 1: investigates the bug via Q&A + code tracing, produces a root cause + fix plan. Only saves the issue docs (via `issue-docs`) under `specs/issues/` once the user confirms they're starting a real fix. |
| **[issue-docs](./issue-docs/SKILL.md)** | `/issue-docs` or "lưu vào specs/issues"; also called by `fix-issue` | Creates/updates linked docs under `specs/issues/<n>-<slug>/` for any task type, picking only the files the current stage needs (`issue.md`, `investigate.md`, `implement.md`, `testcases.md`, `report.md`) and reusing existing ones. |
| **[report](./report/SKILL.md)** | `/report` or ask to report/estimate for a leader | Writes/refines any leader-facing message (bug report, estimate/proposal, status, decision ask) in plain language; structure scales with task scope. |
| **[md-to-github-issues](./md-to-github-issues/SKILL.md)** | `/md-to-github-issues` (no args) | Syncs files under `specs/issues/*.md` that are `Review: Approved` and have no `GitHub Issue: #` yet up to GitHub Issues, writes the issue number back into the file. Manual-only (`disable-model-invocation`). |
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
| **[implement-issue](./implement-issue/SKILL.md)** | `/implement-issue <spec-filename>` or `/implement-issue <spec-filename> local=true` | **Orchestrator** — coordinates full issue implementation: prepare → code → quality (`quality-runner` agent) → finalize. Main entry point for spec implementation. Runs sequentially without stopping; max 3 fix attempts per failing check. `local=true` stops after the quality check — no commit, no push, no PR, no Slack. Manual-only (`disable-model-invocation`). |
| **[implement-prepare](./implement-prepare/SKILL.md)** | used internally by `implement-issue` | Checks out + pulls `develop`/`main`, verifies `Review: Approved`, creates branch `feature/[user]-#[issue]-[slug]`, notifies Slack if configured. |
| **[implement-code](./implement-code/SKILL.md)** | used internally | Reads the spec's Implementation Checklist, codes each item, calls `rule-lookup`/`design-checker`/`code-reviewer` as needed. |
| **[implement-finalize](./implement-finalize/SKILL.md)** | used internally | Commits, updates spec status → `PR: Draft`, pushes, opens a Draft PR via GitHub MCP, notifies Slack. |

---

## Which skill should I use?

| I want to... | Use |
| :--- | :--- |
| Turn a rough idea into a design decision before an issue exists | `feature-discuss` |
| Investigate a reported bug and find the root cause | `fix-issue` |
| Save a discussion/investigation into `specs/issues/` to continue later | `issue-docs` |
| Write/polish a report, estimate, or status update for a leader | `report` |
| Turn `specs/story.md` tasks into individual issue files | `generate-issues` |
| Pull a GitHub Issue into a local spec file, or push local specs to GitHub | `github-issues-to-md` / `md-to-github-issues` |
| Sanity-check a spec before implementation starts | `review-specs` |
| Implement an approved spec end-to-end (branch → code → tests → PR) | `implement-issue` |
| Implement locally without touching git/PR/Slack yet | `implement-issue <spec> local=true` |
| Review a branch/diff against project rules | `review-branch` |
| Get a merged, translated MUST/SHOULD/NIT review before opening a PR | `review-issue` |
| Commit staged changes | `commit` (auto) or `commit format=short auto=false` (one-liner, asks approval first) |
| Commit and push in one go | `commit push=true` |
| Commit multiple unrelated changes as separate, well-scoped commits | `commit-push-by-category` |
| Write a plain-language PR description from the diff | `pr-desc` |

## Common Workflows

**New feature, from idea to PR:**
```
feature-discuss <name>          # discuss design, finalize (runs completeness checklist) → writes specs/issues/<n>.md
  → implement-issue <spec>       # prepare → code → quality → finalize (branch, commit, draft PR)
  → review-issue                 # merged review before requesting human review
  → (fix any MUST/SHOULD findings, re-run review-issue if needed)
```

**Bug fix:**
```
fix-issue                        # investigate, root cause, fix plan
  → (user confirms) scaffolds specs/issues/<n>/{issue,investigate,implement,testcases,report}.md
  → implement-issue <spec> local=true or manual fix
  → review-branch include-staged: true   # review before committing
  → commit push=true
  → report                         # if a report needs to go to a leader/reviewer
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
  → commit push=true
```
