---
name: review-specs
allowed-tools: Read, Grep, Glob, Write
description: Review specification for completeness and clarity. Use when user asks "review spec 1, review-specs #11..."
---

Read the spec from `specs/issues/[issue-number]` → analyze → write feedback to `specs/comments/[ISSUE-NUMBER]-spec-review.md`

**Steps:**
1. Extract the issue number from the user input
2. Find the spec: `grep -l "GitHub Issue.*#N" specs/issues/*.md`
3. Analyze:
   - Acceptance Criteria (clear? measurable? complete?)
   - Implementation Checklist (specific? covers everything?)
   - Design Reference (if `specs/rules/` exists → check tokens; otherwise → skip)
   - Dependencies (blocking/blocked?)
   - Edge cases (error? empty? loading? offline?)
4. Create review file:
   ```markdown
   ---
   GitHub Issue: #N
   Status: READY|PENDING
   ---

   ## Summary
   [2-3 lines]

   ## Well-Defined
   - [list]

   ## Issues Found
   ### [Title]
   > [quote]

   **Problem:** [desc]
   **Suggest:** [fix]

   ## Score (X/10)
   - AC: ✅|❌
   - Checklist: ✅|❌
   - Design: ✅|❌

   ## Status
   - [ ] READY
   - [ ] PENDING — needs clarification
   ```
5. Output a summary with the score + next steps

**Focus:** Clarity & completeness, NOT implementation details
