---
name: review-issue
allowed-tools: Read, Write, Grep, Glob, Bash(git:*), Bash(mkdir:*), Skill
description: Orchestrator that runs review-branch + code-review in parallel, merges the results, classifies scope/basis, translates them into MUST/SHOULD/NIT format with low-risk solutions, and writes them to specs/issues/<n>-<slug>/comment.log. Defaults to Vietnamese output, accepts a `lang` override via ARGUMENTS. Use when the user says "review-issue", "review toàn diện", "review xong feature", or wants a branch reviewed before opening a PR.
---

# Review Issue

Purpose: coordinate two different review sources (internal rules + Anthropic's bug-hunt review) and merge them into a single report for the developer to read, instead of running each by hand and merging manually.

`/review-full [<feature-branch>] [<base-branch>]`

Does not write code, does not fix anything (never uses `--fix`), does not post to GitHub (never uses `--comment`). Review and log only.

**Language:**
- Default output language: Vietnamese
- If ARGUMENTS specifies a language (e.g. `lang: en`, `lang: english`, `en`), write the report in that language instead
- Keep the field labels (Source / Classification / File / Location / Problem / Why it matters / What to change / Suggestion) translated to match the chosen language

## STEP 0: Resolve branch + issue number

1. Resolve the branch the same way `review-branch` does:
   ```bash
   git branch --show-current
   git branch -r | grep -E 'main|master' | head -1
   ```
2. Find the issue number from the branch name, following this repo's current convention (`feature/[username]-#[ISSUE_NUMBER]-[slug]`, see the `implement-prepare` skill):
   - Regex `#(\d+)` on the branch name.
   - If not found, fall back to: `specs/comments/<feature-branch>.log` (keep `review-branch`'s existing fallback convention — do not ask the user).
3. Compute the diff boundary: `git merge-base <base-branch> <feature-branch>`. The review scope is only the changes reachable from `<feature-branch>` but not from that merge-base (i.e. `git diff <merge-base>...<feature-branch>`), plus any staged changes on top. Do not let this boundary silently widen — if `<feature-branch>` contains a merge from `<base-branch>` or another branch, changes that arrived only through that merge (not authored on `<feature-branch>` itself) are out of scope.
4. Resolve the issue folder (only when an issue number was found): an existing `specs/issues/<n>-*/` folder if there is one; otherwise the stem of the spec file whose `GitHub Issue: #<n>` line matches (`grep -l "GitHub Issue.*#<n>" specs/issues/*.md`), created if missing. If neither exists, treat the issue number as not found for the write path in STEP 4.

## STEP 1: Run both review sources as background agents

Scope of review: only the diff computed in STEP 0.3 (`<merge-base>...<feature-branch>` plus staged changes) — not the full history of `<feature-branch>`, not files merged in from `<base-branch>` or elsewhere, and not unstaged/untracked changes. Pass the merge-base explicitly to both agents so neither one falls back to comparing against the tip of `<base-branch>` (which would pull in unrelated changes if the branches have diverged further since the feature branch was cut).

Launch both agents in a single message with two parallel `Agent` tool calls (independent, no dependency between them). Parallel tool calls in one message run concurrently and their results come back as tool results in the same turn — do not fabricate or guess either result before both tool calls have returned.

1. **Agent A** — the `review-branch` agent (`subagent_type: review-branch`); prompt it to review with the resolved `<feature-branch>` `<base-branch>`, `include-staged: true`, and the merge-base from STEP 0.3 as the diff boundary (so committed + staged changes on `<feature-branch>` since it diverged are covered, unstaged working-tree changes and anything merged in from `<base-branch>`/elsewhere stay excluded), and to report back only the structured list of Critical/Warning/Suggestion findings (file, location, problem, why it matters, what to change) — no prose, no fix, no comment.
2. **Agent B** — prompt it to invoke the built-in `code-review` skill targeting `<merge-base>...<feature-branch>` (plus staged changes), explicitly instructing it to review only that range, not unstaged/untracked files and not anything merged in from `<base-branch>`/elsewhere, **WITHOUT** `--comment` or `--fix`, and to report back the structured list of confirmed findings (confidence ≥80) — both bug/correctness findings and any reuse/simplification/efficiency cleanup findings, since STEP 3 maps each to a different severity.

Once both tool calls have returned, list A and list B are each agent's reported findings.

Do not add any additional review beyond these two skills — every finding must come from A or B.

## STEP 2: Merge the results (merge only, no re-verification)

Both A and B already self-verify internally (A: concrete failure scenario; B: confidence score ≥80), so there's no need to cross-verify again — just merge and dedupe:

1. Walk each finding in A and B, grouped by `file`.
2. If two findings are in the same file, within ≤5 lines of each other, and describe the same issue → treat as a duplicate, merge into one entry, note "found by both review-branch and code-review" (higher confidence).
3. A finding that appears in only A or only B → keep as-is and record its source (`review-branch` or `code-review`); the source is written in the final output (STEP 4).

## STEP 2.5: Classify each finding

Classifying is not originating a finding — it only labels findings A/B already reported. For each merged finding, set two labels:

1. **Scope** — one of:
   - `In scope`: the flagged code was added or changed on `<feature-branch>` (appears in the STEP 0.3 diff) and relates to the issue's goal.
   - `Out of scope — pre-existing`: the flagged behaviour already existed at the merge-base. Check with `git show <merge-base>:<file>`; if the same logic is there unchanged, it is pre-existing.
   - `Partly in scope`: part of the flagged code is new on the branch, part is pre-existing.
   - `No change needed — required by spec`: the finding questions a change that the issue spec (the spec file found in STEP 0.4, or `<issue folder>/issue.md`, if present) explicitly requires.
2. **Basis** — one of:
   - `Verified`: the source gave a concrete failure scenario grounded in the code, or a confidence score ≥80.
   - `Assumption`: the source itself says the finding relies on unverified SDK/library/device behaviour, or code-review returned no confidence score for it and the scenario depends on behaviour outside this repo.

## STEP 3: Map severity → MUST / SHOULD / NIT

Classification from STEP 2.5 gates severity first; the source severity only applies to findings that pass the gate.

1. `No change needed — required by spec` → not in the fix list; list it in the "Out of scope / no change needed" section (STEP 4) with one line explaining why.
2. `Out of scope — pre-existing` → not in the fix list and no severity; list it in the "Out of scope / no change needed" section.
3. `In scope` or `Partly in scope` → map the source severity:
   - `Critical` (from review-branch) or a bug from `code-review` → **MUST**
   - `Warning` (from review-branch) or a cleanup/simplification from `code-review` → **SHOULD**
   - `Suggestion` (from review-branch) → **NIT**
   - A finding confirmed by both sources → **MUST** (regardless of original severity), since it's double-confirmed
4. Cap: a finding with Basis `Assumption` is at most **SHOULD**, even if step 3 gave MUST, and its entry must say what to verify before fixing.

## STEP 4: Translate + write the file

For each merged finding, write it in this format (clear, natural language — not a mechanical word-for-word translation):

```markdown
### [No.]. [Severity: MUST / SHOULD / NIT]
- **Source:** `review-branch`, `code-review`, or both
- **Classification:** Scope + Basis from STEP 2.5 (e.g. "Out of scope — pre-existing · Verified"), plus a short reason (e.g. the merge-base already sets the flag unconditionally)
- **File:** file path
- **Location:** line or code block to fix
- **Problem:** short description of what's wrong
- **Why it matters:** the risk or impact if left unfixed
- **What to change:** concrete instructions for the change needed; for an `Assumption` finding, start with what to verify first (test, device, SDK doc) and when the fix can be skipped
- **Suggestion:** the solution, following the rules below
```

Rules for **Suggestion** (goal: lowest risk, smallest impact, least likely to draw a follow-up review comment):
- Read the flagged code before writing the solution, and check the solution against it: it must not reintroduce the problem, break ordering/concurrency the branch relies on, or change behaviour outside the finding.
- Default to one solution: the smallest diff, no new abstraction, matching how the surrounding code is written.
- If more than one reasonable solution exists, list at most 3, one line each with its trade-off, and mark the recommended one.
- If every fix carries more risk than the problem itself, write "Do not fix in this PR" with the reason, plus a ready-to-send reply for the reviewer.
- Any code snippet is labelled "sketch, not compiled".

After the numbered fix list, add a section "Out of scope / no change needed" listing the findings excluded in STEP 3 (steps 1–2): one short entry each with Source, Classification (with reason), File, Location and Problem. Omit the section if it is empty.

(The field labels above are shown in English; write them in the target language — Vietnamese by default.)

Write to `<issue folder>/comment.log` (the folder from STEP 0.4, `specs/issues/<n>-<slug>/`). If no issue number or issue folder was found in STEP 0, write to `specs/comments/<feature-branch>.log`. This report reflects the current state of the branch, so if the file already exists, overwrite it — do not append to a previous run's content.

If neither A nor B found anything, write clearly in the file: "No issues to address on this branch (reviewed via review-branch + code-review)." (translated to the target language).

## STEP 5: Re-check the file before reporting done

Read back the `comment.log` you just wrote, and confirm:
- Every fix-list entry has Source, Classification, File, Location, Problem, Why it matters, What to change and Suggestion filled in meaningfully (none left blank without reason).
- No `Out of scope` or `required by spec` finding sits in the fix list, and no `Assumption` finding is MUST.
- Every Suggestion follows the Suggestion rules in STEP 4.
- Numbers are sequential, no duplicates.
- Every field's content, not just the field labels, is actually written in the target language — no leftover English (or source-language) sentences under translated labels.
- The writing is clear enough that a developer understands what to fix immediately, without needing to re-read the original code.

Report back to the user: count of MUST/SHOULD/NIT, how many are assumption-based, how many were moved to the out-of-scope section, and the log file path — do not repeat the full report content in chat.

## Rules

- Never fix code yourself, never use `--fix`, never post a PR comment.
- Never review beyond the scope of the two skills above — this orchestrator only coordinates + merges + classifies + translates + writes solutions for the reported findings, it never originates new findings.
- If one of the two skills errors or can't run (e.g. missing `gh` auth for code-review), continue with the other's results, and note clearly at the top of the log file which source is missing.
