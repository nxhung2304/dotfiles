---
allowed-tools: Read, Grep, Glob, Write
description: Review specification for completeness and clarity. Use when user asks "review spec 1, review-specs #11..."
---

Đọc spec từ `specs/issues/[issue-number]` → Phân tích → Ghi feedback vào `specs/comments/[ISSUE-NUMBER]-spec-review.md`

**Steps:**
1. Extract issue number từ user input
2. Find spec: `grep -l "GitHub Issue.*#N" specs/issues/*.md`
3. Analyze:
   - Acceptance Criteria (clear? measurable? complete?)
   - Implementation Checklist (specific? cover all?)
   - Design Reference (available? tokens specified?)
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
5. Output summary với score + next steps

**Focus:** Clarity & completeness, NOT implementation details
