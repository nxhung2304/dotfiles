---
name: timesheet
description: Fill the project timesheet Google Sheet with hours per GitHub issue, estimated from the user's Claude Code history and git branch history. Shows a preview and writes only after the user approves. Use when the user says "timesheet", "điền timesheet", "điền giờ công", "tính giờ issue", "/timesheet 72".
---

# Timesheet

Estimate hours per issue with `timesheet.py` in this skill's folder, compare them with the sheet, and write the approved values.

## Prerequisites
Check these before step 1 and stop with the missing item if one fails:
- Google Sheets connector is logged in: the `mcp__claude_ai_Google_Sheets__*` tools are available. If not, tell the user to type `/mcp`, choose "claude.ai Google Sheets", log in with the Google account that can edit the sheet, then run the skill again.
- The account can edit the sheet: reading `'Timesheet'!A1:H1` succeeds. If it fails with a permission error, the user must ask the sheet owner for edit access.
- `gh auth status` succeeds (needed for issue titles and for counting time spent on a pull request toward its issue).
- `python3` is version 3.9 or newer (the macOS built-in one works).

## Target sheet
- "Timesheet - Office Management": spreadsheet ID `1qNqwSRUXXSy_mSiT7Os-dTcMRaCSp9BwwVHxoIQIPaw`, tab `Timesheet`.
- Row 1 is the header, row 2 is the total row, issues start at row 3 sorted by issue number.
- Columns:
  - A Issue: formula `=HYPERLINK("<issue URL>","#<N>")`, so it reads as `#N`.
  - B Task: issue title.
  - C Làm: plan + implement + test hours (`work_hours` from the script).
  - D Review: review + fixing review comments hours (`review_hours` from the script).
  - E Thực tế, G Giảm (h), H Giảm (%): calculated by formulas in row 3 for every row. Never write them.
  - F Estimate: entered by the person. Never write it.

## Arguments
- Issue numbers (`72 63`): only these issues.
- `--since YYYY-MM-DD`: only activity from that date.
- No argument: every issue with estimated hours that has no row in the sheet, or whose row has empty C or D.

## Steps
1. From the repo root run `python3 -I <this skill's folder>/timesheet.py --repo . --json [--issue N ...] [--since DATE]`. Report any stderr message (unreadable transcript lines, pull requests not readable).
2. Read `'Timesheet'!A1:H` and find each issue's row by the `#N` text in column A.
3. Show one preview table: for each issue, the current C and D values next to `work_hours` and `review_hours`, plus the active days. Mark the cells that will be written:
   - Existing row: only C or D cells that are empty. Keep filled cells unless the user names them to overwrite.
   - New row: column A from `git remote get-url origin` as `https://github.com/<owner>/<repo>/issues/<N>`; column B from `gh issue view <N> --json title -q .title`.
4. Under the table, state the limits, one line each:
   - Only time with Claude Code activity on this machine is counted (gaps longer than the idle limit, 30 minutes by default, are dropped), so device testing, meetings and reading without prompting are missing.
   - Time is linked to an issue by the issue or pull request number in prompts, the branch or worktree a command touches, and the issue's spec folder; time before the first such signal in a session goes to the first issue that session names.
   - Claude Code keeps only the last 30 days of history.
   - Each working folder (git worktree) gets its own full time, so folders worked at the same time add up to more than the clock time. Tasks that run inside one folder at the same time share that folder's time.
5. Wait for the user's approval or edits. Do not write before that.
6. Write:
   - Before each write, read column A of the target row again and confirm it is the expected `#N`; row numbers shift after every inserted row.
   - Existing row: `update_values` on the exact approved C or D cells.
   - New row: insert one row with `insert_dimension` (`inheritFromBefore: true`) at the position that keeps column A sorted by issue number, then `update_formulas` for A–D of that row. Then redraw the table borders with `update_spreadsheet` `updateBorders` on A1:H<last row>: top, bottom, left and right `SOLID` rgb(0.72, 0.75, 0.79), innerHorizontal and innerVertical `SOLID` rgb(0.85, 0.87, 0.90).
     Then draw the two thick lines again, since the step above replaces them: bottom of A2:H2 and left of F1:F<last row>, `SOLID_MEDIUM` rgb(0.72, 0.75, 0.79).
7. Read the written rows and the total row back and show them.

## Never
- Write E, F, G, H or row 2, delete rows, or clear cells.
- Touch any other spreadsheet or tab.
