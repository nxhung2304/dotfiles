---
name: review-issue
allowed-tools: Read, Write, Grep, Glob, Bash(git:*), Bash(mkdir:*), Skill
description: Orchestrator chạy review-branch + code-review song song, gộp kết quả, dịch sang tiếng Việt theo format MUST/SHOULD/NIT và ghi vào specs/issues/<issue>/comment.log. Dùng khi user nói "review-issue", "review toàn diện", "review xong feature", hoặc muốn review branch trước khi tạo PR.
---

# Review Issue

Mục đích: điều phối 2 nguồn review khác nhau (rule nội bộ + bug-hunt của Anthropic), gộp lại thành 1 report tiếng Việt duy nhất cho developer đọc, thay vì chạy tay từng cái rồi tự gộp.

`/review-full [<feature-branch>] [<base-branch>]`

Không tự code, không tự sửa lỗi (không dùng `--fix`), không post lên GitHub (không dùng `--comment`). Chỉ review và ghi log.

## STEP 0: Resolve branch + issue number

1. Resolve branch như `review-branch`:
   ```bash
   git branch --show-current
   git branch -r | grep -E 'main|master' | head -1
   ```
2. Tìm issue number từ tên branch theo convention hiện tại của repo (`feature/hung-#[ISSUE_NUMBER]-[slug]`, xem `implement-issue` skill):
   - Regex `#(\d+)` trên tên branch.
   - Nếu không tìm thấy, output path fallback: `specs/comments/<feature-branch>.log` (giữ đúng convention cũ của `review-branch`, không hỏi lại user).

## STEP 1: Chạy 2 nguồn review song song

Gọi cả hai trong cùng 1 message (độc lập, không phụ thuộc nhau):

1. **Skill `review-branch`** với đúng `<feature-branch>` `<base-branch>` đã resolve → nhận list A (Critical/Warning/Suggestion, đã qua bước "verify before assert" của skill đó).
2. **Skill built-in `code-review`** target là branch/diff đã resolve, **KHÔNG** truyền `--comment` và `--fix` → nhận list B (bug/correctness, đã qua bộ lọc confidence ≥80 nội bộ của nó).

Không tự ý review thêm ngoài 2 skill này — mọi finding phải bắt nguồn từ A hoặc B.

## STEP 2: Gộp kết quả (merge, không re-verify lại)

Cả A và B đều đã tự verify ở bên trong (A: concrete failure scenario; B: confidence score ≥80), nên KHÔNG cần verify chéo thêm lần nữa — chỉ gộp và dedupe:

1. Duyệt từng finding của A và B theo `file`.
2. Nếu 2 finding cùng file và line lệch nhau ≤ 5 dòng, mô tả cùng vấn đề → coi là trùng, merge thành 1 entry, ghi chú "phát hiện bởi cả review-branch và code-review" (tăng độ tin cậy).
3. Finding chỉ xuất hiện ở A hoặc B → giữ nguyên, ghi rõ nguồn gốc (không bắt buộc hiện trong output cuối, chỉ dùng nội bộ để trace nếu cần).

## STEP 3: Map severity → MUST / SHOULD / NIT

- `Critical` (từ review-branch) hoặc bug từ `code-review` → **MUST**
- `Warning` (từ review-branch) hoặc cleanup/simplification từ `code-review` → **SHOULD**
- `Suggestion` (từ review-branch) → **NIT**
- Finding được cả 2 nguồn xác nhận trùng nhau → luôn là **MUST** (bất kể severity gốc), vì được double-confirm.

## STEP 4: Dịch sang tiếng Việt + ghi file

Với mỗi finding đã merge, viết theo format sau (dịch rõ ràng, dễ hiểu, không dịch máy móc từng chữ):

```markdown
### [STT]. [Mức độ: MUST / SHOULD / NIT]
- **File:** đường dẫn file
- **Vị trí:** line hoặc đoạn code cần sửa
- **Vấn đề:** mô tả ngắn gọn vấn đề đang xảy ra
- **Tại sao cần sửa:** giải thích nguyên nhân/rủi ro hoặc tác động
- **Cần sửa gì:** hướng dẫn cụ thể nội dung cần thay đổi
- **Đề xuất:** nếu có, đưa ra cách sửa hoặc code/logic phù hợp
```

Ghi vào `specs/issues/<issue-number>/comment.log` (tạo thư mục nếu chưa có). Nếu không tìm được issue number ở STEP 0, ghi vào `specs/comments/<feature-branch>.log`.

Nếu không phát hiện vấn đề gì ở cả A và B, ghi rõ vào file: "Branch không có comment cần xử lý (đã review qua review-branch + code-review)."

## STEP 5: Kiểm tra lại file trước khi báo cáo xong

Đọc lại `comment.log` vừa ghi, đảm bảo:
- Mỗi entry đủ 5 field, không field nào để trống vô nghĩa.
- STT tăng dần, không trùng.
- Câu chữ tiếng Việt rõ ràng, developer đọc hiểu ngay cần sửa gì, không cần đọc lại code gốc mới hiểu.

Báo cáo lại cho user: số lượng MUST/SHOULD/NIT, đường dẫn file log — không lặp lại toàn bộ nội dung report trong chat.

## Rules

- Không tự sửa code, không `--fix`, không post PR comment.
- Không review thêm ngoài phạm vi 2 skill trên — orchestrator chỉ điều phối + gộp + dịch, không tự phát sinh finding mới.
- Nếu 1 trong 2 skill lỗi/không chạy được (vd. thiếu `gh` auth cho code-review), vẫn tiếp tục với kết quả của skill còn lại, và ghi rõ trong phần đầu file log là thiếu nguồn nào.
