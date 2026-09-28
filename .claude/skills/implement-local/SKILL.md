---
name: implement-local
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill, Agent
description: Implement an issue locally — no commit, no PR push, no Slack. Code + quality check only.
---

Purpose: same as `implement-issue`, but stops after the quality check — no commit, no PR, no Slack notification.

**RUN FULLY AUTOMATICALLY, DO NOT STOP BETWEEN STEPS.**

## STEP 1: Prepare
Invoke the `implement-prepare` skill with the spec filename from ARGUMENTS, but explicitly skip its Slack notification step (do not send anything, regardless of `slack-channel-id` config). It still pulls, checks "Review: Approved", and creates the branch.

## STEP 2: Code
Invoke the `implement-code` skill. It reads the spec's Implementation Checklist and implements each item (calling rule-lookup, design-checker, code-reviewer as needed).

## STEP 3: Quality
Invoke the `implement-quality` skill. It detects the project's stack and runs the matching checks, fixing errors via error-fixer as needed.

## STEP 4: SUMMARY

Report once, at the end:
- Files changed
- Checklist items completed
- Test results
- Reminder: "Not committed yet — run /implement-finalize when ready to push"

---

**CRITICAL RULES:**
- Do NOT use AskUserQuestion — always proceed with the default
- Do NOT stop between steps
- Do NOT commit, push, create a PR, or notify Slack
- Tests failing → fix → continue, do NOT stop
