# Task board — handoff to a local session

## Related
- [Original issue](./issue.md)
- [Investigation and all decisions](./investigate.md)
- [Plan](./implement.md)

## Goal
A local web board for `specs/issues` that shows which task needs the user, what is running, what is next and what depends on what, and starts a task in its own worktree + herdr workspace with the right skill.

## State (2026-11-12)
- Branch `claude/dazzling-ramanujan-id70x6` in `nxhung2304/dotfiles`, pushed, no PR yet.
- Built and tested in a cloud session without herdr: herdr and `gh` were replaced by stub scripts. Nothing has run against the real herdr yet.
- Code: `scripts/board/` (Node 22, stdlib only, no build). Start: `scripts/board/board` from a repo root inside a herdr pane → `http://127.0.0.1:4777`.
- Tests: `bash tests/test-board.sh` (20 node tests, all pass).

## Files
| File | Does |
|---|---|
| `board` | Launcher: finds repo root, starts the server, opens the browser |
| `server.js` | HTTP on 127.0.0.1, Host/Origin/Content-Type guard, routes `/api/board`, `/api/start`, `/api/focus`, `/api/clean-up` |
| `specs.js` | Reads `specs/issues/*.md` and folder docs `specs/issues/<n>-<slug>/issue.md`, parses Status/Metadata, resolves `Depends on` (file name, `#NNN` spec number, `#NN` GitHub issue, `PR #N`) |
| `columns.js` | Derives the column of each task from spec + worktrees + herdr agents + PRs; ready/blocked; unlinked worktrees; issues without spec |
| `live-state.js` | `git worktree list`, `herdr pane/agent list` (3 s cache), `gh pr list` and `gh issue list` (60 s cache) |
| `worktree-details.js` | Diff size and uncommitted files per worktree, last lines of the Claude pane (`herdr pane read`) |
| `actions.js` | Start (branch `feature/<user>-#<issue>-<slug>`, `git worktree add`, `scripts/herdr/worktree-workspace open`, send the prompt with `herdr pane send-text`), focus (`scripts/herdr/notify-agent --focus`), clean-up (close workspace + `git worktree remove`, only when clean) |
| `index.html` | Single page, 3 tabs: Đang chạy / Backlog / Đã xong |
| `migrate-specs.js` | Normalizes `Depends on` and adds `Priority` in spec files; dry run unless `--write` |

## Verify first on the real machine
1. Run the board in the mobile repo from a herdr pane. Expected: tasks in the right tabs, Issue/PR links, merged work under Đã xong.
2. Press "Bắt đầu" on a ready task. Expected: new `[WT] feature-…` workspace, Claude receives `/implement-issue <spec> — Branch … is already checked out …` (or `/review-specs #n`, or the "read the issue folder" prompt for folder docs).
3. Check that Claude really skips implement-prepare's checkout/branch steps because of that note. Unverified.
4. When Claude asks something, the row moves to "Cần anh" and shows the question in the grey preview box. The chrome filter in `worktree-details.js` (`TERMINAL_CHROME_PATTERN`) was written against guessed pane text. Unverified, most likely to need tuning.
5. "Mở tab" jumps to the right pane. "Dọn worktree" on a done task removes the worktree and keeps the branch.

## Open decisions
- Run `node ~/dotfiles/scripts/board/migrate-specs.js <mobile repo> --write` on a feature branch of the mobile repo? Dry run is clean except `timesheet-api-permission-check` (free-text dependency, left for a hand edit). Waiting for the user.
- Open a PR for the dotfiles branch? Not asked yet.

## Not done on purpose
- Web chat, in-board diff viewer and comments, auto-commit/auto-PR, auto-start of dependents, `story.md` items on the board. Reasons in `investigate.md`.
