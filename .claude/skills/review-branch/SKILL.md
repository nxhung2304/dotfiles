---
name: review-branch
allowed-tools: Agent
description: Review code changes between two branches for clean code, style conventions, security vulnerabilities, and performance issues. Use when user asks "review code", "review my branch", "review-branch", or "review <branch> against <base>".
---

# Review Branch

Thin entry point: runs the `review-branch` agent so `/review-branch` still works.

`/review-branch [<feature-branch>] [<base-branch>] [include-staged: true|false]`

Example: `/review-branch` or `/review-branch feature/auth main` or `/review-branch include-staged: true`

## Steps

1. Invoke the `review-branch` agent (Agent tool, `subagent_type: review-branch`), passing ARGUMENTS verbatim as its prompt.
2. Relay the agent's result to the user as-is: its summary and the path of the file it wrote under `specs/comments/`. Do not add findings of your own.
