# Task board — investigation

## Related
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

## Open questions
- How to map a worktree/branch back to a spec: branch name pattern from `implement-prepare` must be checked before coding (Unconfirmed).
- How to find the PR of a task with `gh` (by branch name) — Unconfirmed until the branch pattern is checked.
- Whether `herdr worktree open` can create the worktree itself or `wt switch --create` must run first — Unconfirmed.
