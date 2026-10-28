---
name: pr-desc
model: claude-sonnet-5-5
allowed-tools: Bash(git:*), Bash(gh pr list:*), Bash(ls:*), Read
description: Generate a short, plain-language PR description from the diff/commit log between the current branch and base, so a leader/reviewer understands what was done at a glance. Prints content only — does not create/update the PR on GitHub. Defaults to Vietnamese, accepts a `lang` override via ARGUMENTS. Trigger on "viết PR content", "tạo nội dung PR", "tóm tắt PR", "pr-desc", "write PR description".
---

Read the diff + commit log between the current branch and the base branch → summarize into a short, easy-to-understand PR description.

**Language:**
- Default output language: Vietnamese
- If ARGUMENTS specifies a language (e.g. `lang: en`, `lang: english`, `en`, `tiếng anh`), write the output in that language instead
- Keep the section headers translated to match the chosen language (e.g. `## Summary` / `## What was done` / `## Evidence` / `## Merge Danger` for English)
- Bilingual: if ARGUMENTS asks for two languages (e.g. `lang: vi+en`, `bilingual`, `song ngữ`; defaults to Vietnamese + English when no pair is named), write the full description in the first language, then a `---` line, then the same content in the second language — both inside the same code block, same bullets in the same order, shared trailing parts (e.g. `closes #N`, attribution) written once at the end

**Steps:**

1. Determine the base branch:
   - `git symbolic-ref refs/remotes/origin/HEAD` (fallback: try `main`, then `master` if the above has no output)
   - Determine the current branch: `git branch --show-current`
   - If currently on the base branch → tell the user there is nothing to summarize, stop

2. Gather context:
   - `git log <base>..HEAD --oneline` — list of commits
   - `git diff <base>...HEAD --stat` — which files changed, lines added/removed
   - If the commit messages aren't clear enough to understand the change, also read `git diff <base>...HEAD` for the important files
   - If the issue number is known, find its docs with `ls specs/issues/ | grep '^<n>-'` and read what exists (the issue/spec file, `comment.log`, `testcases.md`, `report.md`). Take from them:
     - items deliberately left out of scope or left for a later fix
     - behaviour changes listed under impact/影響範囲 that the diff alone doesn't show
     - the test checklist and any test results already recorded
     - related issues the spec says share the same cause or should be merged

3. Pick the format:
   - Run `gh pr list --author @me --state all --limit 5 --json body`
   - If at least 3 of these PRs share the same section headings, use those headings in the same order instead of the default template below. Map the content onto them (summary, what was done, tests/evidence, notes/risks, related issues)
   - Checkbox sections in that template (e.g. change type, monthly report): tick the change type that matches the commits, and copy the other checkboxes as ticked in the most recent PR
   - If the gh command fails or no shared headings are found, use the default template below

4. Write the PR content in the target language, following this format:

```
## Tóm tắt
- [1 bullet (max 2): WHAT changed and WHY in one sentence — written so someone who doesn't read code can understand, avoid detailed code jargon]

## Đã thực hiện
- **[Short group label]**: [one change/feature at a user/business-understandable level, one line]
- **[Short group label]** (when it has several points):
  - [one point per sub-bullet]
- [Max 3-4 bullets. Group by feature/purpose; merge related removals/changes into one bullet]
- [Don't list individual files, pods/packages, config keys or class names — describe the kind of thing ("gỡ pod AWS, file cấu hình, entitlement Push"), the reviewer reads names in the diff]

## Bằng chứng
- **Trước:** [kết quả/hành vi trước khi sửa]
- **Sau:** [kết quả/hành vi sau khi sửa]

## Rủi ro merge
- [Only items the reviewer must know, each as a bold label + sub-bullets when it has several points: out-of-scope items left for later, known risks, behaviour changes the user will notice, breaking change, migration/schema change and how it was tested, new config/env or setup step (e.g. `pod install`)]

closes #[issue number]
```

(The template above is the Vietnamese default — translate the headers and content to the requested language when one is given.)

5. Print the content for the user (in a code block for easy copying). Do not run `gh pr create` or `gh pr edit` yourself. Below the code block, list every placeholder the user must fill in and every related issue suggested for `closes`.

**Rules:**
- Prioritize BREVITY — a leader/reviewer should understand what was done within 10-15 seconds of reading
- Write from the "what was accomplished" angle, not "how the code changed"
- Avoid detailed implementation jargon (function/variable names) unless truly necessary for context
- Vietnamese must read naturally for a non-developer: short simple sentences, describe what the user/app does instead of technical terms (e.g. "thông báo lỗi" not "alert", "app đang chạy nền" not "background", "chuyển sang màn tiếp theo" not "present"); keep a term only when there is no plain equivalent
- One idea per bullet: when a bullet has several points, split them into sub-bullets — never chain them with `;`
- Keep formatting light: at most one bold label per bullet, `code` only for literal names (paths, commands, endpoints), links only to verified targets (issue/PR number from branch name or commits, docs that exist in the repo)
- If there are multiple unrelated groups of changes, list them as separate bullets in "Đã thực hiện" instead of blending them together
- Leave out minor cleanups (deleted comments, unused variables/imports) and things that were kept unchanged — they don't help the reviewer decide
- "Bằng chứng": only from what is stated in the conversation, commits or the issue's spec files (test run, output, screenshot the user mentioned); never invent a before/after. If there is none but the spec has a test checklist, keep the section and list each checklist case with a placeholder `[result / video to fill in]` (translated to the output language). Drop the section only when there is neither evidence nor a checklist
- "Rủi ro merge": don't write filler lines that tell the reviewer nothing (e.g. "revert là về như cũ", "ảnh hưởng màn X"). If there is nothing to report, drop the whole section
- Mention a test result only if it is stated in the conversation, commits or the issue's spec files; never invent one
- `closes #N`: take N from the branch name (`#(\d+)`) or a commit's `closes #N`; if none is found, drop the line instead of leaving `closes #`
- Related issues from the spec (same cause / to be merged): don't add them to the code block — suggest them below it for the user to confirm
