# Task board — investigation

## Related
- [Handoff](./handoff.md)
- [Original issue](./issue.md)
- [Plan](./implement.md)

## Current state (Confirmed)
- herdr already reports per-agent status `blocked/done/working/idle` — `scripts/herdr/agents-menu:9-31` (`herdr agent list`).
- `herdr pane list` returns each pane's `cwd`, used to map panes to a worktree — `scripts/herdr/worktree-workspace:7-15`.
- One herdr workspace per worktree, with `claude` auto-started, already exists — `scripts/herdr/worktree-workspace:27-41` (`herdr worktree open` + `herdr agent start claude`).
- Same script can close every workspace under a worktree path — `scripts/herdr/worktree-workspace:44-56`.
- macOS notification + jump-to-pane on "needs input" / "done" — `scripts/herdr/notify-agent`, wired as hooks in `.claude/settings.json:63,85`.
- `ai-orchestrate` skill already runs N tasks in parallel in worktrees with a state file and a `needs_you` status — `.claude/skills/ai-orchestrate/SKILL.md`.
- `implement-issue` stops on specs that are not `Review: Approved` (via `implement-prepare`).
- `implement-finalize` writes `PR: Draft` into the spec on the task branch, not on the main checkout — `.claude/skills/implement-finalize/SKILL.md:10`.
- mise provides Node 22 and Python 3.13 — `.config/mise/config.toml`.

## Data problems in the mobile repo specs (Confirmed, `rights_vn-office_management-mobile/specs/issues`)
- Duplicate numbers: 017, 018, 019, 020, 021, 022 each have two different spec files → number cannot be the task key.
- `Depends on` exists in only 14 of 33 specs, in 3 formats: `#018 (title)` (spec number), `#78` (GitHub issue), file slug.
- `PR:` has 7 different spellings (Draft, Todo, Open, In Progress, Merged, `Merged (#59)`, a URL, `—`).
- 3 specs are `Review: Pending`.

## Options considered
- Web chat inside the board → dropped for v1: needs headless Claude (stream-json) and rebuilding permission prompts, diffs, questions. Jump to herdr tab instead.
- Database / GitHub Projects as source → dropped: skills already read `specs/issues/*.md`; one source avoids drift.
- Storing board status in the spec (`Board status` field) → dropped: board runs on the main checkout, so writes would leave develop dirty and conflict with the task branch; spec status only becomes correct after merge.
- Dependency graph view → deferred: "blocked by …" on cards plus hover highlight is enough for v1.

## Decisions
- Q1 No web chat in v1; click card → focus herdr pane.
- Q2 Source of truth = `specs/issues/*.md`.
- Q3 `Depends on` uses spec file names; add `Priority: P1|P2|P3`. (Board status field replaced by Q15.)
- Q4 Drag to In progress → new worktree + herdr workspace running `claude "/implement-issue <spec>"`; blocked if dependencies are not Done.
- Q5 Code lives in dotfiles (`scripts/board/`), usable by any repo.
- Q6 Board runs one task per drag; parallel unattended runs stay in `ai-orchestrate` (later: "run all ready" button calling it).
- Q7 Node 22, stdlib only (`http`, `fs`, `child_process`), single HTML/JS file, no build step, HTML5 drag & drop.
- Q8 One herdr workspace per task worktree, reusing `worktree-workspace`.
- Q9/Q15 Spec stores only `Priority` and `Depends on`; all columns are derived:
  - Todo: no worktree, no PR
  - In progress: worktree exists
  - Needs you: agent in that worktree is `blocked`
  - Review: PR open
  - Done: PR merged, or spec says `PR: Merged`
- Q10 Spec `Review: Pending` → card labelled "not approved"; drag starts `/review-specs <spec>` instead.
- Q11 Full `implement-issue` (commit, push, draft PR, Slack), not `local=true`.
- Q12 Poll herdr every 3 s, `gh` PR state every 60 s; notifications stay with `notify-agent`.
- Q13 One board per repo, started from repo root, default `localhost:4777`.
- Q14 No auto-cleanup; Done cards get a "Clean up" button calling the close logic of `worktree-workspace`.
- Q16 "Ready" column: Todo tasks whose dependencies are all Done, sorted by Priority then number; other Todo cards show "blocked by …", hover highlights related cards.
- Q17 One-off migration script: normalize `Depends on` to file names (`#78` via `GitHub Issue:`, `#018 (title)` via title match), add `—` where missing and `Priority: P2` everywhere; prints a mapping table for approval before writing.
- Q18 More than 3 In progress → warning only, no block.
- Q19 Saved here, in dotfiles `specs/issues/task-board/`.
- Default: server binds to `127.0.0.1` only, since it can run commands.
- 2026-11-12 UI v2 (user asked to fix clutter): 6 kanban columns → one vertical list by attention (Cần anh → Đang làm → Review → Sẵn sàng → Bị chặn → Xong, last 5 done + "xem tất cả"); empty sections hidden; drag & drop replaced by a "Bắt đầu" button (Q4 behaviour unchanged); P2, GH number and merged PR links hidden on rows.

## Open questions (resolved 2026-11-12)
- Branch ↔ spec: Confirmed. `implement-prepare` names branches `feature/<user>-#<GitHub issue>-<slug>` (`.claude/skills/implement-prepare/SKILL.md`, step 3) → board matches `#<n>` to the spec's `GitHub Issue`, then falls back to the file slug.
- PR of a task: `gh pr list --state all --json number,state,headRefName,url` matched by `headRefName` the same way.
- Worktree creation: `herdr worktree open --path` needs an existing worktree (`worktree-workspace` is called by worktrunk's post-switch hook, `.config/worktrunk/config.toml`) → board runs `git worktree add` itself, then `worktree-workspace open`.
- `implement-prepare` checks out `develop` and creates the branch itself, which fails inside a worktree → the board's prompt tells it to skip those steps (args override the skill).
- Starting the command: `herdr pane send-text` + `send-keys enter` into the Claude pane, the same way `scripts/herdr/peer-pair:45-46` does.
- Old spec status formats also mean done: `## **Status:** Merged` (001, 002) and `- ✅ Completed` (022).
- 2026-11-12 Sources widened (user asked why tasks were missing): folder issue docs `specs/issues/<n>-<slug>/issue.md` (7 in the mobile repo) are tasks too; specs that exist only in a task worktree show as blocked with "merge first"; open GitHub issues without any spec are listed in a collapsed section with a copy-command button for `/github-issues-to-md`; `Depends on: PR #N` blocks until that PR is merged. `story.md` items stay off the board (77 open items, owned by `generate-issues`).
- 2026-11-12 Features taken from similar tools (READMEs of langwatch/kanban-code, cline/kanban, BloopAI/vibe-kanban, epatel/claude-agents-dashboard; kanbots.dev and docs.cline.bot did not load):
  - Last lines of the Claude pane on active rows (cline/kanban shows the latest message per card) → `herdr pane read`, chrome lines filtered.
  - PR CI and review state on the PR link (kanban-code) → `statusCheckRollup`, `reviewDecision`.
  - Diff size and uncommitted files per worktree (diff views in cline, vibe-kanban, epatel) → `git diff --shortstat <merge-base>`, `git status --porcelain`.
  - Done → "Dọn worktree": close herdr workspace + `git worktree remove`, only when clean, branch kept (cleanup in all four).
  - Worktrees that match no spec listed with "Mở tab" (kanban-code discovers orphan worktrees and sessions).
  - Not taken: in-board diff viewer and line comments, embedded terminal, auto-commit/auto-PR, auto-start of dependents, cost tracking — they duplicate herdr/skills or skip the user's review.
- 2026-11-12 Tabs (user asked whether to split the single page): "Đang chạy" (needs you, in progress, review, unlinked worktrees, first 3 ready), "Backlog" (all ready, blocked, GitHub issues without spec), "Đã xong" (all done). Tab is remembered per browser; a new "needs you" task switches back to "Đang chạy". Same page and API.

