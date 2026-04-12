---
allowed-tools: Read, Grep, Glob, Write
description: Review specification for completeness and clarity. Use when user asks "review spec 1, review-specs #11..."
---

## Mục đích
Đọc spec từ `specs/issues/[issue-number]`, phân tích completeness & clarity, ghi feedback vào `specs/comments/[ISSUE-NUMBER]-spec-review.md`.

---

## Điều kiện tiên quyết

1. Issue spec file phải tồn tại trong `specs/issues/`
2. Spec phải có tối thiểu: title, description, acceptance criteria

---

## Các bước thực hiện

### 1. Xác định issue number
User gọi: `review-specs 11` → extract number `11`

### 2. Tìm file spec theo GitHub Issue number
Tìm file trong `specs/issues/` chứa `GitHub Issue: #11`:
```bash
grep -l "GitHub Issue.*#11" specs/issues/*.md
```

Ví dụ: `011-calendar-widget.md` chứa:
```
GitHub Issue: #11
```

### 3. Đọc file spec
- Title, description, acceptance criteria
- Implementation checklist
- Design reference/wireframe
- Dependencies (nếu có)
- Notes & edge cases

### 4. Phân tích Completeness

**✅ Acceptance Criteria**
- [ ] Có đầy đủ AC (không mập mờ)?
- [ ] AC có measurable & testable?
- [ ] Có cover hết use cases?

**✅ Implementation Checklist**
- [ ] Có list task cụ thể?
- [ ] Có cover UI, logic, testing?

**✅ Design Reference**
- [ ] Có reference design/wireframe?
- [ ] Có design token specification?

**✅ Dependencies**
- [ ] Có dependency trên specs khác?
- [ ] Liệt kê rõ blocking/blocked?

### 5. Phân tích Clarity

**⚠️ Ambiguity Check**
- Có requirement mơ hồ không?
- Có technical decision chưa rõ?
- Có edge case chưa cover?

**⚠️ Edge Cases**
- Error scenarios?
- Empty states?
- Loading states?
- Offline scenarios?

### 6. Tạo specs/comments/[ISSUE-NUMBER]-spec-review.md

```markdown
---
GitHub Issue: #11
Issue Title: Calendar Widget
Review Date: YYYY-MM-DD
Type: Spec Review
Status: PENDING
---

## **Spec Summary**
[Tóm tắt spec trong 2-3 dòng]

## **✅ What's Well-Defined**
- AC 1: Clear & measurable
- AC 2: Clear & measurable
- Design reference available: [link]
- Implementation checklist complete

## **⚠️ Clarity Issues Found**

### Issue 1: [Title]
> From spec: "[quote from spec]"

**Problem:** [Describe ambiguity]
**Impact:** Dev sẽ phải assume, risk misalignment
**Suggest:** [Clarification or example]

### Issue 2: [Title]
...

## **📋 Completeness Score**
- Acceptance Criteria: ✅ / ❌
- Implementation Checklist: ✅ / ❌
- Design Reference: ✅ / ❌
- Edge Cases: ✅ / ❌
- **Overall: X/10 ready for implementation**

## **🔗 Dependencies**
- Depends on: Issue #XXX (if any)
- Blocks: Issue #YYY (if any)

## **💡 Questions for Dev**
1. [Clarification needed]
2. [Design decision needed]

## **✍️ Approval Checklist**
- [ ] All AC clear & measurable?
- [ ] All ambiguities clarified?
- [ ] Design ready?
- [ ] Ready to assign to dev?

## **Status**
- [ ] PENDING — Needs clarification
- [ ] READY — Ready for implementation
```

### 7. Output to console
```
✅ Spec Review Complete

📄 File: specs/comments/011-spec-review.md
📊 Analysis:
   ✅ Completeness: X/10
   ⚠️ Clarity: X/10

🏷️ Issues Found:
   - X clarity issues
   - X missing details
   - X edge cases not covered

⏭️ Next Step:
   Review specs/comments/011-spec-review.md
   Clarify spec, then ready to implement
```

---

## Lỗi & Xử lý

| Lỗi | Xử lý |
|-----|-------|
| Spec không tồn tại | Dừng, thông báo file không tìm thấy |
| Spec quá mập mờ | Ghi PENDING_CLARIFICATION, list questions |
| Không có design | Warn "⚠️ No design reference", nhưng continue |
| Acceptance criteria không rõ | Ghi cụ thể issue nào không rõ |

---

## Quy tắc quan trọng

- **Focus:** Spec clarity & completeness, NOT implementation details
- **Tone:** Constructive, help dev understand requirements
- **List:** Cụ thể from spec → problem → solution
- **Dependencies:** Always check & list blocking specs
- **Status:** Rõ ràng READY hay PENDING_CLARIFICATION
