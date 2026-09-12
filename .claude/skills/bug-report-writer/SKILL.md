---
name: bug-report-writer
description: Rewrite or refine a bug investigation report / technical report before sending to a leader, reviewer, or team channel. Use this whenever the user drafts or pastes a bug report, investigation summary, root-cause analysis, or "báo cáo điều tra bug" and wants it improved, checked for gaps, or restructured before reporting. Also trigger when the user asks "báo cáo này đã đủ chưa", "còn thiếu gì không", "sửa lại báo cáo", or wants to prepare a report to leader/PM/reviewer about a technical issue. The skill adapts the number of sections to the size/severity of the issue — small issues get a short report, large/high-impact issues get a fuller report — rather than forcing every report into a fixed template.
---

# Bug Report Writer

Giúp viết hoặc sửa lại báo cáo điều tra bug/kỹ thuật trước khi gửi cho leader, reviewer, hoặc team, sao cho báo cáo đủ sâu để người đọc không phải hỏi lại các câu cơ bản (root cause dựa trên gì, đã đối chiếu gì, xử lý hậu quả ra sao).

**Nguyên tắc cốt lõi: KHÔNG áp cứng một form 6-7 mục vào mọi báo cáo.** Số mục phụ thuộc vào quy mô/độ nghiêm trọng của vấn đề. Một bug nhỏ, cô lập, chưa ảnh hưởng ai thì báo cáo 3-4 dòng là đủ. Một bug ảnh hưởng dữ liệu người dùng thật, liên quan nhiều hệ thống, thì cần đầy đủ các mục.

## Quy trình

### Bước 1 — Đánh giá quy mô vấn đề

Trước khi viết, tự hỏi (hoặc hỏi người dùng nếu chưa rõ):

1. **Đã có bằng chứng root cause cụ thể chưa**, hay mới chỉ là phỏng đoán?
2. **Có hệ thống/phiên bản tương đương để đối chiếu không** (ví dụ: bản iOS vs Android, bản cũ vs bản mới, Cordova vs Flutter)?
3. **Vấn đề đã ảnh hưởng đến user/dữ liệu thật chưa**, hay mới phát hiện trong quá trình dev/test?
4. **Mức độ nghiêm trọng/phạm vi ảnh hưởng** — 1 user hay nhiều user, có gây crash/mất dữ liệu/chi phí không?
5. **Có phần nào người viết chưa chắc chắn** cần đánh dấu là giả thuyết thay vì kết luận?

Câu trả lời cho 5 câu này quyết định báo cáo cần bao nhiêu mục ở bước 2. Nếu người dùng đã cung cấp đủ thông tin trong bản nháp, tự suy ra câu trả lời thay vì hỏi lại. Chỉ hỏi khi thực sự không đoán được (ví dụ không rõ vấn đề đã ảnh hưởng user thật hay chưa).

### Bước 2 — Chọn mục cần có (checklist có điều kiện)

| Mục | Luôn có? | Điều kiện thêm vào |
|---|---|---|
| **Hiện tượng** (Symptom) | Luôn có | — |
| **Nguyên nhân** (Root cause) | Luôn có | Nếu đã có bằng chứng code → trích dẫn cụ thể (file/hàm/logic). Nếu chưa chắc → ghi rõ là giả thuyết, không viết như kết luận chắc chắn. |
| **Đối chiếu hệ thống liên quan** (Cross-check) | Chỉ khi có hệ thống/phiên bản tương đương | Bỏ qua nếu không có gì để so sánh. |
| **Giải pháp — ngăn ngừa** (Forward-fix) | Luôn có | — |
| **Giải pháp — khắc phục hậu quả** (Remediation) | Chỉ khi vấn đề đã ảnh hưởng dữ liệu/user thật | Bỏ qua nếu bug chưa từng chạy ở production hoặc không để lại hậu quả tồn đọng. |
| **Đánh giá mức độ nghiêm trọng / phạm vi** (Impact & Severity) | Chỉ khi vấn đề đủ lớn (ảnh hưởng nhiều user, hoặc leader cần ưu tiên P0/P1/P2) | Bỏ qua với bug nhỏ, cô lập. |
| **Ước lượng effort** (Estimate) | Chỉ khi cần lên kế hoạch sửa (có code fix đi kèm) | Bỏ qua nếu báo cáo chỉ để thông báo, chưa có hướng fix. |
| **Việc cần xác nhận thêm** (Open questions) | Chỉ khi có phần chưa chắc chắn | Nếu mọi thứ đã rõ ràng và có bằng chứng, không cần mục này. |

**Quy tắc rút gọn:** nếu sau khi áp bảng trên, báo cáo chỉ còn 2 mục (Hiện tượng + Nguyên nhân) thì gộp thành một đoạn ngắn thay vì chia mục rời rạc — báo cáo nhỏ nên đọc liền mạch, không cần heading rườm rà.

**Quy tắc mở rộng:** nếu vấn đề lớn (nhiều user, mất dữ liệu, liên quan nhiều team/hệ thống), có thể thêm mục phụ ngoài bảng trên nếu ngữ cảnh đòi hỏi (ví dụ: rủi ro bảo mật, ảnh hưởng compliance) — bảng trên là sàn tối thiểu, không phải giới hạn cứng.

### Bước 3 — Viết/sửa báo cáo

- Với mỗi mục **Nguyên nhân**: không viết "đây là bug do X" nếu chưa trích được đoạn code hoặc logic cụ thể. Nếu người dùng đưa link issue/PR liên quan, đối chiếu trực tiếp: "issue #X sửa ở đâu, và vì sao chỗ đang lỗi không nằm trong phạm vi sửa đó".
- Với mục **Đối chiếu**: nêu rõ điểm giống/khác, không chỉ liệt kê hai hệ thống.
- Với mục **Remediation**: luôn trả lời câu hỏi "vậy user đã bị ảnh hưởng rồi thì sao?" — đây là câu hỏi leader/PM gần như luôn hỏi nếu bug đã chạy ở production.
- Giữ văn phong ngắn gọn, đúng thuật ngữ kỹ thuật đã dùng trong bản gốc (không tự ý đổi tên biến, tên hàm, tên issue).
- Nếu người dùng viết bằng tiếng Việt, giữ nguyên tiếng Việt trong báo cáo output.

### Bước 4 — Rà lại trước khi đưa ra bản cuối

Tự kiểm tra bằng 3 câu hỏi:
- Có kết luận nào chưa có bằng chứng đi kèm không? → nếu có, hạ xuống thành giả thuyết hoặc thêm bằng chứng.
- Có câu hỏi "hiển nhiên" nào người đọc (leader) sẽ hỏi lại mà báo cáo chưa trả lời không? (ví dụ: "vậy user cũ thì sao", "vậy tại sao Android không bị")
- Số mục có tương xứng với quy mô vấn đề không? (báo cáo nhỏ mà dài dòng, hoặc báo cáo lớn mà sơ sài, đều cần sửa lại)

## Ví dụ áp dụng độ dài theo quy mô

**Bug nhỏ, đã rõ nguyên nhân, chưa ảnh hưởng ai:**
> Hiện tượng: [X]. Nguyên nhân: [đoạn code Y gây ra Z]. Đã fix ở PR #N, không cần xử lý gì thêm cho user hiện tại.

(3 câu, không cần heading.)

**Bug lớn, ảnh hưởng dữ liệu user thật, có hệ thống để đối chiếu (case Garmin là ví dụ điển hình):**
> Đầy đủ các mục: Hiện tượng → Nguyên nhân (kèm bằng chứng code) → Đối chiếu (Cordova vs Flutter) → Giải pháp ngăn ngừa → Giải pháp khắc phục hậu quả → Ước lượng → Việc cần xác nhận thêm.
