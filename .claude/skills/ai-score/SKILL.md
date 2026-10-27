---
name: ai-score
description: Weekly self-review of how well the user works with AI. Scores the 5 skill criteria from scripts/ai-metrics/rubric.md with quoted evidence, explains why the costliest tasks took so much effort and proposes a fix for each, proposes 1–2 actions for next week, writes the result to ~/.ai-metrics/reviews/<date>.json and renders the HTML report. Use when the user says "ai-score", "chấm điểm dùng AI", "review tuần", "báo cáo AI tuần này", or wants the AI metrics report filled with scores and causes.
---

# AI review

Fill the AI-judged parts of the AI metrics report ("Có tiến bộ không?", "Các task tốn công", "Tuần tới làm gì?") and the per-project "Điểm yếu lặp lại". Part 1 is computed by the script; never compute or change numbers yourself.

**Language:** write every text field of the review in Vietnamese unless ARGUMENTS say `lang: en`.

**Privacy:** transcripts and specs contain project code and data. Read them locally only. Never send their content to any external tool, MCP server or web service.

## Steps

1. Export the data (default: the last full week, Monday to Sunday; ARGUMENTS may pass `weeks-ago: N`, where 0 is the current week, or `project: name`):
   ```bash
   python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --weeks-ago 1 --json ~/.ai-metrics/review-input.json
   ```
   Read `~/.ai-metrics/review-input.json`. It holds `week_start` (Monday, YYYY-MM-DD), `trend`, `tasks` (each with numbers, `costly`, `cwd`, `sessions[].transcript`) and `skills`.
   If `tasks` is empty, tell the user there is no data for the period and stop.

2. Read the rubric at the path in the `rubric` field. Score exactly as it says.

3. Collect evidence. Do not read raw transcript files; condense them first:
   ```bash
   python3 ~/dotfiles/scripts/ai-metrics/ai_transcript.py <transcript paths...>
   ```
   - `costly: true` is set per project: up to 3 costliest tasks of each project that has at least 2 assigned tasks. Projects below that are skipped.
   - Ignore the AI-metrics tooling itself: tasks or sessions that used the skills `ai-score`, `ai-improve` or `ai-review`, or whose work is building `~/dotfiles/scripts/ai-metrics/`. Do not use them for scores, costly-task causes, `weaknesses` or `actions`, in any project.
   - Start with the tasks marked `costly: true`, then sample the others until each criterion has evidence or clearly has none.
   - For tasks with an issue number, look in `<cwd>/specs/issues/<n>-*/` and `<cwd>/specs/<n>*/` for `decision.md` and other spec files.

4. Score the criteria:
   - Criteria 1, 3, 5: score 1–5 by the rubric. Every score needs one short verbatim quote (`evidence`) and where it came from (`source`: transcript path + time, or file path).
   - No quote → `score: null` and say in `evidence` what was missing.
   - Criteria 2 and 4 are measured by the script, not by you. Set `score: null` and put in `evidence` which data is still missing (bug/LOC, code survival, `/ai-quiz` for 2; normalized tokens for 4).

5. Explain each `costly: true` task: one plain-language cause, backed by one quote. Name what happened (e.g. missing spec, unclear prompt, AI guessed wrong repeatedly). Do not blame the tool without a quote. Add one proposed solution per task (1–2 short bullets, concrete, tied to the cause). Every bullet in `cause` and `solution` is at most ~15 words. The first bullet of each is the main one: the report shows only those by default and hides the rest under "Chi tiết".
   - Add `specs`: the spec file names found in step 3 for this task (empty list if none). Add `suggested_skill` only if one skill that really exists in the input `skills` or the skill list would have helped; otherwise omit it.
   - Add `excerpts`: 1–3 more short verbatim lines from the transcript that show the cause (shown under "Chi tiết"). Never include code, secrets, tokens or personal data.
   - If the task has no real issue number (`task` is `issues`, `0`, or similar), write a short `title` (max ~6 words) summarising what the task was about, from the transcript. Keep `project` and `task` unchanged for matching.

6. For each project that has at least 2 `costly: true` tasks, write 1–3 `weaknesses`: patterns that repeat across that project's costly tasks, not a single task's cause. Each is at most ~15 words. Skip the project if no pattern repeats.

7. Write 1–2 actions for next week. Each must be concrete, doable in one week, and tied to the weakest score or a costly-task cause.

8. Write the review to `<review_dir>/<YYYY-MM-DD>.json` (create the folder if needed; overwrite today's file if it exists):
   ```json
   {
     "date": "YYYY-MM-DD",
     "week_start": "<week_start từ input>",
     "summary": ["mạnh ở đâu", "yếu ở đâu", "lưu ý về số liệu nếu có"],
     "scores": [
       {"criterion": 1, "name": "Kiểm soát output / đánh giá phương án", "score": 3, "evidence": "trích nguyên văn", "source": "đường dẫn + thời điểm"}
     ],
     "costly_tasks": [
       {"project": "<project từ input>", "task": "<task từ input>", "title": "<tên ngắn, bắt buộc nếu task không phải số issue thật>", "cause": ["ý 1", "ý 2"], "solution": ["giải pháp 1"], "evidence": "trích nguyên văn", "excerpts": ["câu nguyên văn 1"], "specs": ["decision.md"], "suggested_skill": "tên skill, bỏ trường này nếu không có"}
     ],
     "projects": [
       {"project": "<project từ input>", "weaknesses": ["điểm yếu lặp lại 1"]}
     ],
     "actions": ["việc 1", "việc 2"]
   }
   ```
   `summary`, `cause`, `solution` and `weaknesses` are lists of 1–3 short bullets, one idea each. Each item in `actions` is one short sentence.
   Markup in `summary`, `cause`, `solution`, `weaknesses` and `actions` (the report renders it):
   - Start a `summary` bullet with `Mạnh:`, `Yếu:` or `Lưu ý:` when it fits; the report highlights only these labels. Do not use `**...**`.
   - Write local files as full paths in backticks (`` `~/dotfiles/.claude/hooks/ai_track.py` ``); existing paths become clickable links. Do not use backticks around a bare filename.
   `scores` lists all 5 criteria in order 1–5, using these names: 1 "Kiểm soát output / đánh giá phương án", 2 "Kiểm soát code", 3 "Cách tìm hiểu vấn đề", 4 "Tiết kiệm token", 5 "Chất lượng tài liệu". `project` and `task` must be copied exactly from the input so the report can match them.

9. Render and open the report:
   ```bash
   python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --html ~/.ai-metrics/report.html && open ~/.ai-metrics/report.html
   ```

10. Reply with: the summary line, the weakest criterion, and the actions. Mention any criterion left `null` and why.

## Rules

- This is a self-improvement tool (Goodhart's law): judge what happened, do not round scores up to be kind.
- Fewer than 2 weeks of data: say that trends are not reliable yet.
- A skill with fewer than 5 tasks: do not draw conclusions about it.
