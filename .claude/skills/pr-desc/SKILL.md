---
name: pr-desc
allowed-tools: Bash(git:*), Read
description: Generate a short, plain-language PR description from the diff/commit log between the current branch and base, so a leader/reviewer understands what was done at a glance. Prints content only — does not create/update the PR on GitHub. Defaults to Vietnamese, accepts a `lang` override via ARGUMENTS. Trigger on "viết PR content", "tạo nội dung PR", "tóm tắt PR", "pr-desc", "write PR description".
---

Read the diff + commit log between the current branch and the base branch → summarize into a short, easy-to-understand PR description.

**Language:**
- Default output language: Vietnamese
- If ARGUMENTS specifies a language (e.g. `lang: en`, `lang: english`, `en`, `tiếng anh`), write the output in that language instead
- Keep the section headers translated to match the chosen language (e.g. `## Summary` / `## What was done` / `## Impact & Notes` for English)

**Steps:**

1. Determine the base branch:
   - `git symbolic-ref refs/remotes/origin/HEAD` (fallback: try `main`, then `master` if the above has no output)
   - Determine the current branch: `git branch --show-current`
   - If currently on the base branch → tell the user there is nothing to summarize, stop

2. Gather context:
   - `git log <base>..HEAD --oneline` — list of commits
   - `git diff <base>...HEAD --stat` — which files changed, lines added/removed
   - If the commit messages aren't clear enough to understand the change, also read `git diff <base>...HEAD` for the important files

3. Write the PR content in the target language, following this format:

```
## Tóm tắt
[1-3 sentences, WHAT changed and WHY — written so someone who doesn't read code can understand, avoid detailed code jargon]

## Đã thực hiện
- [Bullet points, each item is one change/feature at a user/business-understandable level]
- [Don't list individual files, group by feature/purpose instead]

## Ảnh hưởng / Lưu ý
- [Only include if relevant: breaking change, new config/env needed, migration required, etc. Drop this section if there's nothing worth noting]
```

(The template above is the Vietnamese default — translate the headers and content to the requested language when one is given.)

4. Print the content for the user (in a code block for easy copying). Do not run `gh pr create` or `gh pr edit` yourself.

**Rules:**
- Prioritize BREVITY — a leader/reviewer should understand what was done within 10-15 seconds of reading
- Write from the "what was accomplished" angle, not "how the code changed"
- Avoid detailed implementation jargon (function/variable names) unless truly necessary for context
- If there are multiple unrelated groups of changes, list them as separate bullets in "Đã thực hiện" instead of blending them together
