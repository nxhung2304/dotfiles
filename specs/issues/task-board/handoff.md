# Task board — handoff to a local session

## Related
- [Original issue](./issue.md)
- [Investigation and all decisions](./investigate.md)
- [Plan](./implement.md)

## Goal
A local web board for `specs/issues` that shows which task needs the user, what is running, what is next and what depends on what, and starts a task in its own worktree + herdr workspace with the right skill.

## State (2026-11-12)
- Branch `claude/dazzling-ramanujan-id70x6` in `nxhung2304/dotfiles`, pushed, no PR yet.
- Built in a cloud session with stub herdr and `gh`. On 2026-11-12 it was run against the real herdr and `gh` on the user's machine (mobile repo); results below.
- Rebased onto `master` (adds `vibe-issue`). Local commits only, not pushed.
- Code: `scripts/board/` (Node 22, stdlib only, no build). Start: `scripts/board/board` from a repo root inside a herdr pane → `http://127.0.0.1:4777`.
- Tests: `bash tests/test-board.sh` (26 node tests, all pass).

## Files
| File | Does |
|---|---|
| `board` | Launcher: finds repo root, starts the server, opens the browser |
| `server.js` | HTTP on 127.0.0.1, Host/Origin/Content-Type guard, routes `/api/board`, `/api/start`, `/api/focus`, `/api/clean-up` |
| `specs.js` | Reads `specs/issues/*.md` and folder docs `specs/issues/<n>-<slug>/issue.md`, parses Status/Metadata, resolves `Depends on` (file name, `#NNN` spec number, `#NN` GitHub issue, `PR #N`) |
| `columns.js` | Derives the column of each task from spec + worktrees + herdr agents + PRs; ready/blocked; unlinked worktrees; issues without spec |
| `live-state.js` | `git worktree list`, `herdr pane/agent list` (3 s cache), `gh pr list` and `gh issue list` (60 s cache) |
| `worktree-details.js` | Diff size and uncommitted files per worktree, last lines of the Claude pane (`herdr pane read`) |
| `actions.js` | Start (branch `feature/<user>-#<issue>-<slug>`, `git worktree add`, `scripts/herdr/worktree-workspace open`, send the prompt with `herdr pane send-text`), auto-run (`/vibe-issue <spec> max-parallel=1` in a `[AUTO]` workspace at the repo root, spec files only), focus (`scripts/herdr/notify-agent --focus`), clean-up (close workspace + `git worktree remove`, only when clean) |
| `index.html` | Single page, 3 tabs: Đang chạy / Backlog / Đã xong |
| `migrate-specs.js` | Normalizes `Depends on` and adds `Priority` in spec files; dry run unless `--write` |

## Verify on the real machine (run 2026-11-12)
1. Done. Tasks, tabs, Issue/PR links and merged work under Đã xong are right. Fixed: branches without `#` (`feature/hung-16-…`) were not matched, so task 012 showed as ready (`columns.js`).
2. Done. A new `[WT]` workspace opens and Claude receives the prompt. Fixed: `herdr agent start claude` failed with `agent_name_taken` when another pane already had that name, so the second workspace never got Claude (`scripts/herdr/worktree-workspace` now names agents `claude-<pane>`).
3. Done. `implement-prepare` creates its own worktree and stops when the branch or path exists, so the old "skip checkout" note was unlikely to work. The spec-file prompt now runs `implement-code`, `quality-runner`, `implement-finalize` directly. Checked with a throwaway approved spec: Claude loaded `implement-code` first, did not run `implement-prepare` and did not create another worktree. It was interrupted before commit; nothing was pushed. Throwaway spec, worktree and branch were removed. `quality-runner` and `implement-finalize` were not reached.
4. Done with a real AskUserQuestion dialog: row moves to "Cần anh". Fixed: preview now cuts the input box and footer, drops dialog hints and shows 6 lines when blocked (`worktree-details.js`).
5. "Mở tab" works. "Dọn worktree" refuses the main checkout (409) as designed. Actual removal not tried: no done task has its own worktree.
Also fixed: "Worktree chưa gắn task" lists only branches with a real issue number.

## Open decisions
- Run `node ~/dotfiles/scripts/board/migrate-specs.js <mobile repo> --write` on a feature branch of the mobile repo? Dry run is clean except `timesheet-api-permission-check` (free-text dependency, left for a hand edit). Waiting for the user.
- Open a PR for the dotfiles branch? Not asked yet.
- Auto-run rows are not tracked: the `[AUTO]` pane runs at the repo root, so the board cannot map it to a task or show "Cần anh" for it until `vibe-issue` creates the worktree. Reading `~/.ai-metrics/orchestrator/<run-id>.json` would fix it (file shape unchecked, no run yet).

## Not done on purpose
- Web chat, in-board diff viewer and comments, auto-commit/auto-PR, auto-start of dependents, `story.md` items on the board. Reasons in `investigate.md`.
