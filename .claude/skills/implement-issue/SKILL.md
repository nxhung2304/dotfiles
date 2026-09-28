---
name: implement-issue
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill, mcp__github__*, mcp__slack__*
description: Orchestrator for the full implement-an-issue flow. Does not code directly.
---

Purpose: coordinate the full flow of implementing an issue from its spec, end to end.

**IMPORTANT: Run fully automatically, do NOT stop between steps:**

RUN ALL OF THE FOLLOWING STEPS IN ONE EXECUTION — DO NOT STOP TO REPORT IN BETWEEN:

## STEP 1: Prepare
Invoke the `implement-prepare` skill with the spec filename from ARGUMENTS. It pulls, checks "Review: Approved", creates the branch, and notifies Slack if configured.
Keep its returned `{ branch_name, issue_number, title, thread_ts }` — you'll need `thread_ts` for step 4.

## STEP 2: Code
Invoke the `implement-code` skill. It reads the spec's Implementation Checklist and implements each item (calling rule-lookup, design-checker, code-reviewer as needed).
Keep its returned `{ files_changed, checklist_items_completed }`.

## STEP 3: Quality
Invoke the `implement-quality` skill. It detects the project's stack and runs the matching checks, fixing errors via error-fixer as needed.
Keep its returned `{ tests_passed, files_fixed, warnings }`.

## STEP 4: Finalize
Invoke the `implement-finalize` skill, passing along `thread_ts` from step 1. It commits, updates the spec status, pushes, opens a draft PR, and notifies Slack.
Keep its returned `{ pr_url, files_committed }`.

## STEP 5: FINAL SUMMARY

Report a summary ONLY ONCE, at the very end:
- PR link
- Files changed
- Checklist items completed
- Test results

---

**CRITICAL RULES:**
- Do NOT use AskUserQuestion — always proceed with the default
- Do NOT stop between steps
- Tests failing → fix → continue, do NOT stop
- Do NOT write code yourself — delegate each phase to its skill (implement-prepare, implement-code, implement-quality, implement-finalize), which in turn call subagents (rule-lookup, code-reviewer, error-fixer, design-checker) as needed
