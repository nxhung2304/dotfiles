---
name: review-issue
allowed-tools: Read, Write, Grep, Glob, Bash(git:*), Bash(mkdir:*), Skill
description: Orchestrator that runs review-branch + code-review in parallel, merges the results, translates them into MUST/SHOULD/NIT format, and writes them to specs/issues/<issue>/comment.log. Defaults to Vietnamese output, accepts a `lang` override via ARGUMENTS. Use when the user says "review-issue", "review toàn diện", "review xong feature", or wants a branch reviewed before opening a PR.
---

# Review Issue

Purpose: coordinate two different review sources (internal rules + Anthropic's bug-hunt review) and merge them into a single report for the developer to read, instead of running each by hand and merging manually.

`/review-full [<feature-branch>] [<base-branch>]`

Does not write code, does not fix anything (never uses `--fix`), does not post to GitHub (never uses `--comment`). Review and log only.

**Language:**
- Default output language: Vietnamese
- If ARGUMENTS specifies a language (e.g. `lang: en`, `lang: english`, `en`), write the report in that language instead
- Keep the field labels (File / Location / Problem / Why it matters / What to change / Suggestion) translated to match the chosen language

## STEP 0: Resolve branch + issue number

1. Resolve the branch the same way `review-branch` does:
   ```bash
   git branch --show-current
   git branch -r | grep -E 'main|master' | head -1
   ```
2. Find the issue number from the branch name, following this repo's current convention (`feature/[username]-#[ISSUE_NUMBER]-[slug]`, see the `implement-prepare` skill):
   - Regex `#(\d+)` on the branch name.
   - If not found, fall back to: `specs/comments/<feature-branch>.log` (keep `review-branch`'s existing fallback convention — do not ask the user).

## STEP 1: Run both review sources as background agents

Scope of review: committed and staged changes only. Unstaged working-tree modifications and untracked files are out of scope — do not let either agent review them.

Launch both as background agents in the same message (independent, no dependency between them), using the `Agent` tool:

1. **Agent A** — prompt it to invoke the `review-branch` skill with the resolved `<feature-branch>` `<base-branch>` and `include-staged: true` (so committed + staged changes are both covered, unstaged working-tree changes stay excluded), and to report back only the structured list of Critical/Warning/Suggestion findings (file, location, problem, why it matters, what to change) — no prose, no fix, no comment.
2. **Agent B** — prompt it to invoke the built-in `code-review` skill targeting the resolved branch/diff, explicitly instructing it to review only committed + staged changes (not unstaged/untracked files), **WITHOUT** `--comment` or `--fix`, and to report back only the structured list of confirmed bug/correctness findings (confidence ≥80).

Do not proceed to STEP 2 until both agents' completion notifications have arrived — do not fabricate or guess their results while waiting. Once both are back, list A and list B are each agent's reported findings.

Do not add any additional review beyond these two skills — every finding must come from A or B.

## STEP 2: Merge the results (merge only, no re-verification)

Both A and B already self-verify internally (A: concrete failure scenario; B: confidence score ≥80), so there's no need to cross-verify again — just merge and dedupe:

1. Walk each finding in A and B, grouped by `file`.
2. If two findings are in the same file, within ≤5 lines of each other, and describe the same issue → treat as a duplicate, merge into one entry, note "found by both review-branch and code-review" (higher confidence).
3. A finding that appears in only A or only B → keep as-is; track its source internally (not required in the final output, just for tracing if needed).

## STEP 3: Map severity → MUST / SHOULD / NIT

- `Critical` (from review-branch) or a bug from `code-review` → **MUST**
- `Warning` (from review-branch) or a cleanup/simplification from `code-review` → **SHOULD**
- `Suggestion` (from review-branch) → **NIT**
- A finding confirmed by both sources → always **MUST** (regardless of original severity), since it's double-confirmed

## STEP 4: Translate + write the file

For each merged finding, write it in this format (clear, natural language — not a mechanical word-for-word translation):

```markdown
### [No.]. [Severity: MUST / SHOULD / NIT]
- **File:** file path
- **Location:** line or code block to fix
- **Problem:** short description of what's wrong
- **Why it matters:** the risk or impact if left unfixed
- **What to change:** concrete instructions for the change needed
- **Suggestion:** if applicable, a suggested fix or logic
```

(The field labels above are shown in English; write them in the target language — Vietnamese by default.)

Write to `specs/issues/<issue-number>/comment.log` (create the directory if missing). If no issue number was found in STEP 0, write to `specs/comments/<feature-branch>.log`.

If neither A nor B found anything, write clearly in the file: "No issues to address on this branch (reviewed via review-branch + code-review)." (translated to the target language).

## STEP 5: Re-check the file before reporting done

Read back the `comment.log` you just wrote, and confirm:
- Every entry has all 5 fields filled in meaningfully (none left blank without reason).
- Numbers are sequential, no duplicates.
- The writing is clear enough that a developer understands what to fix immediately, without needing to re-read the original code.

Report back to the user: count of MUST/SHOULD/NIT, and the log file path — do not repeat the full report content in chat.

## Rules

- Never fix code yourself, never use `--fix`, never post a PR comment.
- Never review beyond the scope of the two skills above — this orchestrator only coordinates + merges + translates, it never originates new findings.
- If one of the two skills errors or can't run (e.g. missing `gh` auth for code-review), continue with the other's results, and note clearly at the top of the log file which source is missing.
