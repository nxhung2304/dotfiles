---
name: ai-improve
description: Reads the weekly AI reviews and metrics, then proposes concrete changes to skills and rules that would fix the costly tasks and weak criteria. Proposals only, never edits skills or rules. Writes ~/.ai-metrics/improvements/<date>.md. Use when the user says "ai-improve", "đề xuất cải thiện skill", "cải thiện rule", "sửa skill theo báo cáo", or after /ai-score has produced a review.
---

# AI improve

Turn the scores and costly tasks from `/ai-score` into proposed edits to the user's skills and rules. Propose only; the user decides.

**Language:** write in Vietnamese unless ARGUMENTS say `lang: en`.

**Privacy:** reviews, metrics and transcripts contain project data. Read locally only. Never send their content to any external tool, MCP server or web service.

## Steps

1. Read every `~/.ai-metrics/reviews/*.json` (newest first) and note how many weeks exist. Export fresh numbers if needed:
   ```bash
   python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --days 7 --json ~/.ai-metrics/review-input.json
   ```
2. Pick targets: the lowest-scoring criteria and every `costly_tasks` entry (`cause`, `solution`, `evidence`).
3. A pattern counts only if it shows up in 2+ weeks of reviews. With fewer than 2 weeks, say so and list candidates as "chưa đủ dữ liệu", not as proposals. A skill with fewer than 5 tasks gets no conclusion.
4. For each target, read the files that could change it, then draft a proposal. Candidates:
   - `~/.claude/CLAUDE.md` and `~/dotfiles/.claude/code-rules/`
   - `~/dotfiles/.claude/skills/*/SKILL.md`
   - `~/dotfiles/.claude/agents/`
   Read the real file before proposing; never describe a rule or skill from memory.
5. Write `~/.ai-metrics/improvements/<YYYY-MM-DD>.md` (create the folder; overwrite today's file). Each proposal has:
   - **Vấn đề**: the weak criterion or costly task, with one verbatim quote and its source from the reviews.
   - **Sửa file nào**: full path in backticks.
   - **Sửa gì**: the exact wording to add or change, short.
   - **Bỏ gì**: which existing rule or line to drop or merge, or "không có" if truly nothing.
   - **Rủi ro**: what could get worse.
   - **Cách đo**: which score or metric should move, and when to check.
6. Reply with the proposal titles and the path of the file.

## Rules

- Never edit skills, rules, hooks or settings. Writing the proposals file is the only write.
- Max 3 proposals per run, ordered by impact. Fewer if the evidence is thin.
- Do not propose changes that only make a score look better (Goodhart's law). Each must change how the work is done.
- Do not touch existing logic the evidence does not require changing; say why if you must.
- Mark anything not verified in the files as "guess".
