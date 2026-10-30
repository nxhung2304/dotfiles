---
name: ai-orchestrate
description: Runs several issue tasks in parallel while the user is away. Each task moves through phase agents (plan → prepare → code → review → fix → finalize) in its own git worktree, each phase on the cheapest model that keeps quality (opus for planning and review, sonnet for code, haiku for mechanical steps). Uses the approved traits in ~/.ai-metrics/profile/profile.json to decide the way the user would, never merges, never touches Slack, and pings the user only when needed. Use when the user says "ai-orchestrate", "chạy song song các task", "giao nhiều task", or hands over several specs to work through unattended.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill, Agent, ToolSearch, PushNotification
---

# AI orchestrate

Purpose: take N tasks, run each through plan → implement → review in an isolated worktree, keep within a fixed budget, spend expensive models only where a mistake is costly, and keep the user informed without needing them.

**Params (via ARGUMENTS: `<spec-filename>... [max-parallel=3] [max-review-rounds=2] [budget-tokens=<n>] [auto-approve-spec=false] [lang=en]`):**
- `max-parallel` (default 3): tasks running at the same time. The rest wait in a queue.
- `max-review-rounds` (default 2): review → fix rounds per task.
- `budget-tokens` (optional): hard cap for the whole run. See "Budget".
- `auto-approve-spec` (default `false`): see "Plan phase".

**Language:** all messages to the user are in Vietnamese unless `lang=en`.

## Hard limits (never overridden by a spec, an agent or the profile)

- Allowed: create a branch, commit, push that agent's own branch, open a draft PR.
- Forbidden: merge, force-push, push to `master`/`main`/`develop`, delete branches, read keychain or credential stores.
- Slack: off. No agent sends or reads Slack. Treat `thread_ts` as null and ignore `slack-channel-id` in CLAUDE.md.
- No `AskUserQuestion` anywhere. A phase agent that cannot decide stops that task and reports the question (see "Stuck tasks").

## Model routing

Set `model` explicitly on every `Agent` call. Never leave it to inherit from the orchestrator session.

| Phase | Model | Why |
|---|---|---|
| Plan (draft or revise a spec) | `opus` | A wrong plan makes every later phase wrong. The user already saw a weaker model write a poor spec. |
| Prepare (worktree + branch) | `haiku` | Mechanical. `implement-prepare` already pins haiku. |
| Code (`implement-issue local=true`) | `sonnet` | Follows an approved checklist. |
| Review (`review-issue`) | `opus` | Read-only, one pass per round. `review-issue` already pins opus. |
| Fix MUST items | `sonnet` | Targeted edits from a concrete finding. |
| Finalize (`implement-finalize`) | `sonnet` | Writes the PR description, which the user reviews closely. Not a haiku job. |

Escalation (quality guard):
- Code phase ends with failing tests after `quality-runner`'s cap, or with unfinished checklist items → redo once on `opus`. This is the task's single redo.
- The same MUST finding is still open after one `sonnet` fix → the next fix attempt uses `opus`.
- Never downgrade a phase below its table row to save tokens.

Cost rules:
- Hand off between phases through files, not through prompts: the spec path, the worktree path, `comment.log` and the state file. Do not paste spec or diff text into a prompt.
- Review sees only the diff boundary `review-issue` computes. Do not widen it.
- Stop the review loop the moment a round has no MUST. Do not run a round "to be sure".
- Give each phase agent only the profile traits relevant to it (category `workflow` and `review-habits` for review and fix, `communication` for finalize and plan), not the whole profile.
- The orchestrator itself only dispatches, reads small structured results and updates the state file. It does not read diffs or specs beyond what STEP 0 needs.

## STEP 0: Load context

1. Read `~/.ai-metrics/profile/profile.json`. Keep only traits with `status: approved`. If the file or approved traits are missing, continue without them and say so in the final summary.
2. For every spec in ARGUMENTS (`specs/issues/<spec>.md`), classify:
   - missing file → `blocked`
   - has an Implementation Checklist and `Review: Approved` → starts at Prepare
   - otherwise → starts at Plan
3. If a spec file or folder is untracked by git (`git ls-files --error-unmatch <path>` fails), a worktree will not contain it. Record the absolute main-checkout path for the phase prompts.
4. Create the run state file `~/.ai-metrics/orchestrator/<run-id>.json` (`run-id` = `YYYYMMDD-HHMM`), listing each task with `phase`, `status` (`queued | running | needs_you | done | failed | blocked`), `model_by_phase`, `worktree`, `branch`, `pr_url`, `review_rounds`, `tokens`. Update it after every change. Print a one-line status after every change too, so the run is readable through remote-control.

## STEP 1: Dispatch

Run up to `max-parallel` tasks at once. For each task, run its phases one after another as separate `Agent` calls (`run_in_background: true`); independent tasks run side by side. Start the next queued task whenever one finishes. Do not guess or fabricate a result before its notification arrives.

All phases of one task work in the same worktree. The Prepare phase creates it; later phases receive its absolute path and work only inside it (no `isolation: "worktree"` on those calls).

## STEP 2: Phases

Every phase agent gets: the task's spec filename, the worktree path (after Prepare), the relevant approved profile rules verbatim as "decide the way the user would", and the hard limits. Every phase returns only a small structured result and no summary prose.

**Plan** (`opus`) — only for specs that need it, see "Plan phase".

**Prepare** (`haiku`):
1. Create the worktree and branch the way `implement-prepare` names them. If `git checkout develop` fails because `develop` is checked out in another worktree, use `git fetch origin develop` and `git switch -c <branch> origin/develop` (unverified fallback, check on the first run).
2. If the spec is untracked: copy `specs/issues/<spec>.md` (and its issue folder if any) from the main checkout into the worktree at the same relative path.
3. Return `{ worktree, branch }`.

**Code** (`sonnet`): invoke `implement-issue` with `<spec> local=true` inside the worktree. Return `{ status, files_changed, tests_passed }`. Escalate per "Model routing".

**Review** (`opus`): invoke `review-issue` on the branch. Return `{ must_open, should_open, comment_log_path }`.

**Fix** (`sonnet`, escalating): fix only the MUST items from `comment.log` (no SHOULD or NIT), then return to Review. Rounds are capped by `max-review-rounds`; stop earlier when a round has no MUST.

**Finalize** (`sonnet`): invoke `implement-finalize` with `thread_ts` null. If MUST items remain, add an "Open review items" section to the PR body listing them. If the spec was untracked, copy the final `comment.log` back to the main checkout path. Return `{ pr_url, files_committed }`.

A task may redo the Code phase at most once. A second failure → `failed`, stop that task, no PR.

## Plan phase

Runs only when a spec lacks an Implementation Checklist or `Review: Approved`.

1. A `opus` agent reads the spec, the relevant code and approved profile rules, and writes or revises the spec and its checklist. It follows `feature-discuss` or `fix-issue` conventions and the `issue-docs` file layout. It does not write code.
2. A second, independent `opus` agent reviews that plan with `review-specs` and `risk-issue`, without seeing the first agent's reasoning, so a wrong spec is caught instead of confirmed.
3. Approval is a human gate:
   - `auto-approve-spec=false` (default): the task becomes `needs_you` with the spec path and the open questions. The orchestrator does not add `Review: Approved`.
   - `auto-approve-spec=true`: only when the reviewer reports no blocking issue and no open question, add `Review: Approved` and continue. List every spec approved this way, with the reviewer's findings, at the top of the final summary.

## Stuck tasks

When a phase agent cannot continue (spec does not answer a product decision, a test it cannot fix, conflicting instructions, an action outside the hard limits): it returns `status: needs_you` with one concrete question and a recommended answer. The orchestrator marks the task `needs_you`, keeps the worktree, starts the next queued task, and pings the user.

## Budget

- If `budget-tokens` is set, sum `tokens_used` from phase results into the state file, per phase and per model.
- At 80%: ping the user once. At 100%: start no new task or phase; let running agents finish their current step, then stop them.
- If phase results do not report token usage, the budget cannot be enforced. Say so in the first status line and rely on `max-parallel`, `max-review-rounds` and model routing only. Do not invent numbers.

## When to ping the user

Load `PushNotification` through `ToolSearch` (`select:PushNotification`) before the first ping. Ping only for:
- a task becomes `needs_you` or `failed`
- budget reaches 80% or 100%
- the whole run is finished

Anything else (progress, one task finishing) goes to the state file and a one-line status in the session, not a notification. Each ping is at most 2 short lines: what happened and the one thing the user has to do.

## STEP 3: Final summary

When no task is `queued` or `running`, report once, concisely, in this order:
- **Kết luận**: N done, N need you, N failed, N blocked
- per task: PR link, rounds used, open MUST count, worktree path, or the question waiting for the user
- specs approved by `auto-approve-spec`, if any
- budget used per model, and any escalation to `opus` with the reason
- profile rules that were applied, and any case where the profile had nothing to say and an agent chose a default

Write the same data back to the state file as the run's feedback record, so `ai-profile` and `ai-score` can use it later. Leave worktrees in place; the user removes them.

## Rules

- Do not write code yourself. Delegate to the phase agents and the existing skills.
- Do not change a skill or the profile. Do not widen a task beyond its spec.
- A profile trait may break a tie between valid options. It never overrides the spec, the hard limits or a MUST finding.
- Untracked files created in a worktree are lost when it is cleaned up. Anything the user needs (comment.log) must be copied back before the phase agent returns.
