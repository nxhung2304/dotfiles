# Task board — plan

Status: v1 implemented in `scripts/board/` (steps 1, 3–6). Step 2 written, dry run checked, not yet applied to the mobile repo.

## Related
- [Handoff](./handoff.md)
- [Original issue](./issue.md)
- [Investigation](./investigate.md)

## Affected files
- New: `scripts/board/server.js`, `scripts/board/index.html`, `scripts/board/migrate-specs.js`
- Reused, not changed: `scripts/herdr/worktree-workspace`, `scripts/herdr/notify-agent`
- Data (mobile repo, after approval): `specs/issues/*.md` — `Depends on`, `Priority`

## Steps
1. Check open questions first: branch name pattern in `implement-prepare`, how `herdr worktree open` creates a worktree, how to find a PR by branch with `gh`.
2. Migration script (`migrate-specs.js`) → dry run prints mapping table → user approves → write → commit on a feature branch of the mobile repo.
3. Server, read side:
   - Parse specs → `{ file, title, number, priority, dependsOn, reviewApproved, prField }`
   - `git worktree list` → spec ↔ worktree via branch name
   - Every 3 s: `herdr agent list` + `herdr pane list` → agent status per worktree (match `cwd`)
   - Every 60 s: `gh pr list --state all` → PR state per branch
   - Derive column (Todo / Ready / In progress / Needs you / Review / Done) and "blocked by"
   - `GET /api/tasks` returns the list
4. Server, action side (bind `127.0.0.1:4777`):
   - `POST /api/start` → refuse if deps not Done → create worktree → open herdr workspace → start `claude "/implement-issue <spec>"` (or `/review-specs <spec>` when not approved)
   - `POST /api/focus` → focus that agent's pane (same as `notify-agent --focus`)
   - `POST /api/cleanup` → close workspaces of that worktree (no worktree deletion with uncommitted changes)
5. UI (`index.html`): columns, drag Todo/Ready → In progress, "not approved" and "blocked by" labels, hover highlight of deps, warning when > 3 In progress, click Needs you card → focus.
6. Launcher: `scripts/board/board` runs `node server.js` from the current repo root and opens the browser.

## Order and dependencies
- Step 1 before 3–4 (branch ↔ spec mapping depends on it).
- Step 2 can run in parallel with 3; the board works without it but shows fewer dependencies.
- Step 5 after 3–4.

## Risks
- Branch ↔ spec mapping wrong → card shows wrong column; check with a real worktree.
- herdr CLI output fields may change between versions; parse defensively.
- `gh` rate limit / auth missing → Review/Done columns fall back to the spec's `PR:` field.
- Starting `claude` with a slash command as first prompt: confirm the CLI accepts it via `herdr agent start` (Unconfirmed).
