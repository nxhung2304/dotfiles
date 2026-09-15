---
name: investigate-bug
description: Interactively investigate a reported bug through systematic reproduction, root cause analysis, and fix planning. Use when user asks "investigate bug", "tìm lỗi", "điều tra bug", "đánh giá bug/lỗi", "đánh giá thử", "review nghi ngờ", or points to an existing investigation/bug report file (e.g. investigate.md, root-cause note with a list of "nghi ngờ"/suspicions) and wants an assessment of it — not only when starting a fresh investigation from scratch.
---

# Investigate Bug

Systematically investigate a reported bug through interactive questioning, code tracing, and structured analysis. Ends with a clear root cause and actionable fix plan.

## Process

### 1. Gather bug context

If the user provides an issue number, read the file from `specs/issues/<number>.md` or fetch via `gh issue view <number>`.  
If not, ask the user to describe:
- What is the expected behaviour?
- What actually happens?
- Steps to reproduce (UI flow, API call, data state)?
- Is it reproducible 100% of the time or intermittent?
- Which platform / environment (iOS, Android, staging, prod)?

Ask **one question at a time**. Never present a list of questions upfront.

### 2. Explore the codebase before asking

Before asking the user anything that code can answer — read the code:
- Find the feature's entry point (route, controller, screen, handler)
- Trace the execution path relevant to the bug
- Check recent commits touching those files: `git log --oneline -20 -- <file>`
- Look for related tests to understand expected behaviour
- Check `CLAUDE.md`, `CONTRIBUTING.md`, or `README.md` for project conventions

Only ask the user about things the codebase cannot answer.

### 3. Reproduce the bug (in your head)

Walk through the code path step by step as if executing the bug scenario:
- Identify the exact line or condition where behaviour diverges from expectation
- Note any state, timing, or data dependency that could cause intermittent failure
- Distinguish between **always-fails** vs **sometimes-fails** bugs early — they have different root causes

If you cannot trace the failure: ask one targeted question about the missing context (data shape, device state, network condition, etc.).

### 3.5 Evaluating an existing list of suspicions

If the user hands you a file/note that already lists multiple suspected causes (e.g. `investigate.md` with several numbered "nghi ngờ"), do not merge them into one narrative or produce a single combined conclusion. For **each** suspicion, independently:

1. State what you actually read/checked (file, line, log) to verify it.
2. Label the verdict explicitly as one of:
   - **Đã xác nhận** (confirmed) — code/log directly shows this, cite the evidence (file:line or log excerpt).
   - **Chưa xác nhận** (unconfirmed) — you have a plausible mechanism but no direct evidence it actually happened / actually causes the reported symptom. Say so in these words, don't blur it into a confirmed finding.
   - **Không xác nhận được với thông tin hiện có** (cannot confirm with what's available) — say what extra info/repro would be needed to decide.
3. Never upgrade a "chưa xác nhận" to a stated fact by proximity to a confirmed one in the same paragraph — a wrong confirmation here sends the whole investigation in the wrong direction, so keep each verdict visually and textually separate.

### 4. Root cause analysis

Once the failure point is located, determine the root cause category:

| Category | Examples |
|---|---|
| Logic error | Wrong condition, off-by-one, bad operator |
| State / race condition | Async timing, shared mutable state |
| Null / uninitialized | Missing null-check, unset field |
| Data contract mismatch | API response shape changed, wrong type |
| Config / environment | Wrong endpoint, missing flag, platform difference |
| Regression | Recent commit changed behaviour unintentionally |

State your root cause hypothesis clearly: *"The bug occurs because X, which causes Y when Z."*

Then verify: does this hypothesis explain **all** reported symptoms? If not, surface the gap and adjust.

### 5. Assess impact

Before proposing a fix, answer:
- Which files / modules are affected?
- Are there other callsites that have the same bug?
- Does fixing this risk breaking anything else?
- Is there a workaround users can apply in the meantime?

### 6. Propose a fix plan

Only produce a fix plan (including any "fix this first" ordering/priority) once the root cause has actually been confirmed to explain the reported symptom — via reproduction, a log that directly shows the failure, or code that unambiguously proves the mechanism. Reading code and finding a *plausible* bug is not the same as confirming it caused *this* report.

If reproduction/confirmation hasn't happened yet, stop here instead of proposing a fix plan. State clearly: what's confirmed so far, what's still an unconfirmed hypothesis, and the next concrete step needed to confirm it (repro steps, a log to capture, an experiment to run). Ask the user whether they want to attempt reproduction before you propose fixes.

Once confirmed, output a structured fix plan:

```
## Root Cause
[One-sentence statement]

## Affected Files
- path/to/file.dart — what needs to change

## Fix Plan
1. [Concrete step]
2. [Concrete step]
...

## Verification
- [ ] How to confirm the fix works (manual test / unit test / log)

## Risk
- [What could break, and how to guard against it]
```

Ask the user: *"Does this plan look right? Want me to proceed with the fix?"*

## Rules

- Ask one question at a time — never a list
- Always recommend an answer / hypothesis — never ask cold
- Explore code before asking — don't ask what the code already answers
- State the root cause as a clear hypothesis, not a vague guess
- End every investigation with an explicit fix plan **only if** the root cause is confirmed — otherwise end with what's confirmed, what's not, and how to confirm it next
- When multiple suspicions exist, verify and label each independently (confirmed / unconfirmed / cannot confirm) — never blend them into one conclusion
