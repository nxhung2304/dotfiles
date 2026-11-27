---
name: create-issue
description: Create one GitHub issue for an ad-hoc piece of work that is not a task in specs/story.md — a chore, docs change, cleanup, small bug, or follow-up found while doing other work — with a duplicate check, the repo's language and labels, and a draft shown before anything is posted. Use whenever the user says "tạo issue", "tạo issue riêng", "mở issue cho việc này", "tách ra issue khác", "create an issue for X", "track this in an issue", or agrees to split leftover work into its own issue, even if they don't name this skill. For tasks listed in specs/story.md use generate-issues; for pushing approved local issue files to GitHub use md-to-github-issues.
---

# Create issue

Turn one piece of ad-hoc work into one GitHub issue that a teammate can read and act on without the chat that produced it.

## 0. Pick the right tool first
- The work is a task in `specs/story.md` → stop and use `generate-issues` (it owns numbering, dependencies and the local issue file).
- An approved local issue file already exists without a GitHub number → suggest the user run `/md-to-github-issues` (it is user-invoked only).
- Several issues at once → run this skill once per issue, but search for duplicates for all of them up front.

## 1. Check you may post
Creating an issue is a remote write. Follow the user's remote-write rules (global and project `CLAUDE.md`): if posting is not allowed for this repo, still do steps 2–6, then write the body to a file and give the exact `gh issue create` command instead of running it.

If the project `CLAUDE.md` has `github-account: <user>` and `gh api user -q .login` differs, switch with `gh auth switch --hostname github.com --user <user>`, and switch back when done: the active account is global and affects other repos.

## 2. Search for an existing issue
Run `gh issue list --state open --search "<keywords>"` with 2–3 keyword variants (feature name, file or area, English and the user's language). If one covers the same topic, propose extending it (edit body or add a comment) instead of creating a new one, and let the user choose. Duplicate issues split discussion and are the most common way tracking goes stale.

Also search closed issues (`--state closed`, a few results) for the issue that built the area: link it as related context, not as a duplicate.

## 3. Check the premise
Before drafting, check the claim behind the issue against the code and specs (does the behaviour exist, does a spec already define it). An issue built on a wrong premise sends a teammate after a problem that isn't there. If the evidence contradicts the request, stop and tell the user what you found and the options (don't file, file as a question, file with the corrected framing) before writing the draft.

## 4. Decide language and references
- Language: read the project `CLAUDE.md` from disk (the copy loaded at session start can be outdated) and use what it says for issues; if it says nothing, match the last few issues in the repo.
- Write for a reader who was not in the chat: plain words, no local task numbers, file-internal labels or chat shorthand. Refer to other issues and PRs as `#N` so GitHub links them; local-only numbers (e.g. a story task number) mean nothing on GitHub.
- State facts you verified; label anything unverified as a guess.

## 5. Write the body
Pick the template by type and drop any section that would be empty. When a decision is still open, add an `## Open Questions` section to any template; if the whole issue is a question, use only Description + Open Questions. Keep it short: a teammate should understand the goal in the first two lines.

**Task / feature**
```
## Description
<2–4 lines: what and why>

## Acceptance Criteria
- [ ] <testable outcome, max 8>

## Out of Scope
- <only if a reader might expect it here>

## Notes
- <dependencies as "Depends on #N", open decisions, risks; max 4>
```

**Bug**
```
## Description
<what is wrong, where, since when if known>

## Steps to Reproduce
1. <step>

## Expected / Actual
- Expected: <...>
- Actual: <...>

## Notes
- <evidence: logs, screenshots, commit; suspected cause labeled as a guess>
```

**Chore / docs**
```
## Description
<1–3 lines: what changes and why now>

## Changes
- <file or area: change>

## Notes
- <impact on teammates, follow-ups>
```

Title: short, imperative, in the chosen language, no type prefix unless the repo uses one.

## 6. Labels
Read `gh label list` and pick only existing labels that fit (type, area). Add a phase label only when the work belongs to a single phase. Do not create labels without asking; mention a missing one instead.

## 7. Show the draft
Show title, labels and body, and say which existing issues you checked and what you verified in step 3. Wait for approval unless the user already said to create it without review.

## 8. Create or update, then record
- Updating an existing issue: `gh issue edit <N> --title ... --body-file <file>`, and add/remove labels with `--add-label` / `--remove-label`.
- Write the body to a file in the scratchpad and run `gh issue create --title ... --label ... --body-file <file>`; never pass long bodies inline.
- Report the URL.
- If the project has `specs/issues/`, ask whether to also create a local issue file (via `issue-docs`). If yes, put `GitHub Issue: #N` in it and keep it in the same language as the GitHub issue, so the two copies do not drift.
- If the work appears in a project record (e.g. `specs/story.md`, a decision log), add the `#N` there.
