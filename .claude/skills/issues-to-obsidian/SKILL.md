---
name: issues-to-obsidian
allowed-tools: Read, Bash(git rev-parse:*), Bash(git remote:*), Bash(ls:*), Bash(gh issue:*), Bash(gh pr:*), Bash(gh auth:*), Bash(gh api:*), Bash(python3:*)
description: One-way sync of the current repo's issues (specs/issues status + GitHub issue/PR state) into a marked block of the Obsidian note "My Tasks.md", so several projects can be tracked in one place. Only rewrites the block between the repo's sync markers; never touches lines the user wrote by hand. Use when the user says "sync tasks", "đồng bộ My Tasks", "cập nhật My Tasks", or asks to refresh the task list in Obsidian from the repo.
---

# Issues to Obsidian

Repo → Obsidian, one way, on demand. The note is the user's hand-curated list; this skill only owns its own block.

Target note: `/Users/rightsvn-hunga/vaults/personal/00-Inbox/My Tasks.md`

## Step 1 — Identify the repo

- `repo` = basename of `git rev-parse --show-toplevel`
- `owner/name` = from `git remote get-url origin`
- GitHub account: if the project `CLAUDE.md` has `github-account: <user>` and `gh api user -q .login` differs → `gh auth switch --hostname github.com --user <user>`

## Step 2 — Collect issues from specs

Scan `specs/issues/` recursively for `<n>-*.md`, `<n>.md` and folders `<n>-*/`. For each issue number `n` keep:
- Title: the `[ISSUE-#n] <title>` first line, else the first `#` heading, else the folder slug
- Spec status: the first `- PR: <value>` line under `## **Status:**` (the format `implement-finalize` writes). Missing → none.
- Spec path (repo-relative), for the link line

## Step 3 — Collect GitHub state

- Issues: `gh issue list --state all --limit 300 --json number,title,state,closedAt,url`
- PRs: `gh pr list --state all --limit 200 --json number,title,state,isDraft,headRefName,body,url,mergedAt`
- Link a PR to issue `n` when its body contains `closes #n` / `fixes #n` (any case), or its `headRefName` contains `#n-` or ends with `#n`. Prefer the open PR, else the latest merged.

## Step 4 — Decide what goes in the block

Include issue `n` when it has a spec file **and** is OPEN on GitHub, or when it already appears in the current block (so a just-closed issue shows once as done, then drops out on the next sync).

Status line per issue, first match wins:
| Condition | Line |
|---|---|
| Issue CLOSED or PR merged | `- [x] Done` + PR url if any |
| Open PR, draft | `- [ ] PR: Draft <url>` |
| Open PR, ready | `- [ ] PR: In review <url>` |
| No PR, spec status present | `- [ ] PR: <spec value>` |
| Otherwise | `- [ ] Chưa có PR` |

## Step 5 — Render the block

Match the note's style: tab indentation, checkboxes, GitHub url after the title.

```
<!-- sync:<repo> -->
	- [ ] Issues đang mở (sync <YYYY-MM-DD HH:MM>)
		- [ ] #<n> <title>: <issue url>
			- [ ] PR: Draft <pr url>
<!-- /sync:<repo> -->
```

- Sort by issue number descending.
- An issue line is `[x]` only when its status line is `[x]`.

## Step 6 — Show, confirm, write

1. Read the note. Find `<!-- sync:<repo> -->` … `<!-- /sync:<repo> -->`.
   - Not found → show the project headings in the note and ask which one the block goes under (insert right after that heading's existing lines, before the next top-level heading).
2. Print the old block vs the new block. If identical → say "không có thay đổi" and stop.
3. Ask for approval, unless the user already said to write without asking.
4. Write with a `python3 -I` script: read UTF-8, normalize to NFC, replace only the text between the markers (or insert the marked block), write back. Never rewrite or reformat anything outside the markers.
5. Re-read the block and confirm it matches what was approved.

## Report

Short: which issues were added / changed / marked done / dropped, plus any issue whose PR could not be matched.
