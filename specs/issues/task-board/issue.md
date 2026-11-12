# Task board for parallel vibe-coding tasks

## Related
- [Investigation](./investigate.md)
- [Plan](./implement.md)

## Status
- Discussion done (feature-discuss Q1–Q19), no GitHub issue yet.
- Rename this folder to `<n>-task-board` once an issue exists.

## Original request
> Tôi đang vibe coding dự án này
> Thao tác trong herdr, mỗi tab sẽ là 1 task
> Nhưng đôi khi rối quá vì làm 2-3 task song song, không rõ task nào phụ thuộc task nào, nên làm gì tiếp
> Tôi đang có ý tưởng: tạo trang web local, mỗi task tương tự issue, kéo từ todo -> progress thì tự gọi skill để làm, khi cần hỏi tôi thì có chat hay gì đó / thông báo. Tôi sẽ chat
> Các issue có gắn sự phụ thuộc, thứ tự ưu tiên,...

## Scope decided
- Local web kanban per repo, reading `specs/issues/*.md` as the only source of truth.
- Shows dependencies, priority and which tasks are ready next.
- Dragging a card to In progress opens a herdr workspace on a new worktree running the right skill.
- "Needs you" is shown on the board; answering happens in the herdr tab, not in a web chat (web chat deferred).
- Out of scope for v1: web chat, dependency graph view, multi-repo board, auto-cleanup of worktrees, running many tasks at once (stays with `ai-orchestrate`).
