---
name: implement-issue
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill, Agent, mcp__claude_ai_Slack__*
description: Orchestrator for the full implement-an-issue flow. Does not code directly. Pass `local=true` to skip commit, push, PR and Slack.
disable-model-invocation: true
---

Purpose: coordinate the full flow of implementing an issue from its spec, end to end.

**Params (via ARGUMENTS: `<spec-filename> [local=true]`):**
- `local` (default `false`): if `true`, stop after the quality check — no commit, no push, no PR, no Slack notification.

**IMPORTANT: Run fully automatically, do NOT stop between steps:**

RUN ALL OF THE FOLLOWING STEPS IN ONE EXECUTION — DO NOT STOP TO REPORT IN BETWEEN:

## STEP 1: Prepare
Invoke the `implement-prepare` skill with the spec filename from ARGUMENTS. It pulls, checks "Review: Approved", creates the branch, and notifies Slack if configured.
If `local=true`, explicitly skip its Slack notification step (do not send anything, regardless of `slack-channel-id` config).
Keep its returned `{ branch_name, issue_number, title, thread_ts }` — you'll need `thread_ts` for step 4.

## STEP 2: Code
Invoke the `implement-code` skill. It reads the spec's Implementation Checklist and implements each item (calling rule-lookup, design-checker, code-reviewer as needed).
Keep its returned `{ files_changed, checklist_items_completed }`.

## STEP 3: Quality
Invoke the `quality-runner` agent. It detects the project's stack, runs the matching checks, and fixes source errors itself.
Retry cap: max 3 fix attempts per failing check, then stop and report what was tried — the agent enforces this; do not re-invoke it for the same failing check.
Keep its returned `{ tests_passed, files_fixed, warnings }`.

## STEP 4: Finalize (skip if `local=true`)
Invoke the `implement-finalize` skill, passing along `thread_ts` from step 1. It commits, updates the spec status, pushes, opens a draft PR, and notifies Slack.
Keep its returned `{ pr_url, files_committed }`.

## STEP 5: FINAL SUMMARY

Report a summary ONLY ONCE, at the very end:
- PR link (omit if `local=true`)
- Files changed
- Checklist items completed
- Test results, plus any check that hit the retry cap
- If `local=true`: "Not committed yet — run /implement-finalize when ready to push"

---

**CRITICAL RULES:**
- Do NOT use AskUserQuestion — always proceed with the default
- Do NOT stop between steps
- Tests failing → quality-runner fixes (max 3 attempts per check) → continue; after the cap, report and continue, do NOT stop
- If `local=true`: do NOT commit, push, create a PR, or notify Slack
- Do NOT write code yourself — delegate each phase to its skill or agent (implement-prepare, implement-code, quality-runner, implement-finalize), which in turn call subagents (rule-lookup, code-reviewer, design-checker) as needed
