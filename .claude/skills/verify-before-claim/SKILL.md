---
name: verify-before-claim
description: Operationalizes the "verify before stating as fact" rule for completeness/correctness claims about code — phrases like "this is all the files", "every case is covered", "nothing else uses X", "all accounted for", "this is safe/correct". Use this BEFORE sending any such claim, especially when comparing, merging, migrating, or auditing file sets, configs, dependencies, or behavior across versions/branches/profiles. Mandatory whenever the instinct is to sample/eyeball a few representative files and then generalize to "all"/"every" — run the mechanical check instead of asserting from the sample.
---

Sampling a few files that look representative and then saying "every file checked" or "all accounted for" is a guess wearing the clothes of a fact. The fix isn't "be more careful by feel" — it's to run a command that actually computes the full set, every time this kind of claim is about to be made.

## Catch it before sending

If the draft response contains any of: "all files", "every case", "complete", "accounted for", "nothing else", "fully covers", "confirmed", "this is safe" — stop and ask: *did I compute the full set, or did I pick examples that seemed likely and generalize?* If the latter, don't send yet — run step 2 first.

## Mechanical checks by claim type

- **"These are all the overlapping/changed/relevant files"** (comparing two dirs/profiles/versions):
  `diff -rq <dir_a> <dir_b>` or
  `comm -12 <(find A -type f | sort) <(find B -type f | sort)`
  Not: diffing the handful of files that seemed likely to overlap.

- **"Nothing else references/uses X"**:
  `grep -rn "X" <whole repo/scope>` — not just the files already open in context.

- **"This gem/config/flag is unused / already present / needed"**:
  grep the actual manifest + lockfile (Gemfile/Gemfile.lock, package.json, etc.) right now — don't infer from what was discussed earlier in the conversation.

- **"All callers/usages were updated"**:
  grep for the old symbol repo-wide *after* the edit. Zero hits is the proof; "I updated the ones I found" is not.

- **"This is safe / won't break X"**:
  read the actual code path(s) for X. Don't reason from the diff alone.

## Show the receipt

State the claim together with (or right after) the command whose output it's based on — the verification should be visible in the response, not just asserted.

## If you can't verify right now

Say so explicitly and label the claim a guess/assumption, not a fact. Never phrase an unverified claim as "confirmed," "verified," or "all accounted for."

## Why this exists (a real miss)

Claimed "re-checked by diffing every file that exists in both web and api profiles" after hand-picking 8 files to diff. A later `comm -12 <(find base -type f | sort) <(find profiles/api -type f | sort)` turned up a 9th overlapping file (`Makefile`) that had been missed. "I diffed the files I checked" and "I diffed every file" are different claims — only the set-computing command proves the second one.
