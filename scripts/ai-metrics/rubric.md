# Rubric chấm kỹ năng dùng AI (bản MVP)

Áp dụng cho tiêu chí 1, 3, 5. Tiêu chí 2 và 4 dùng số liệu từ script.

## Quy tắc chấm
- Thang 1–5. Mức 1, 3, 5 có mô tả; mức 2 và 4 là giữa hai mốc kề.
- Mỗi điểm phải trích bằng chứng: câu trong transcript hoặc đoạn trong file `specs/issues/<n>-<slug>/`. Không có trích dẫn thì không chấm điểm đó.
- Thiếu file bằng chứng thì ghi `N/A`, không tự suy đoán và không tính vào điểm trung bình.
- Không tự tính số liệu. Chỉ dùng số script đã tính sẵn.

## 1. Kiểm soát output / đánh giá phương án
Bằng chứng: transcript; `decision.md` nếu có.
- 1: chấp nhận phương án đầu tiên của AI, không hỏi lý do.
- 3: có hỏi phương án khác hoặc ưu nhược, nhưng chưa phản biện cụ thể.
- 5: yêu cầu nhiều phương án, phản biện ít nhất một điểm của AI, nêu được vì sao chọn.

## 3. Cách tìm hiểu vấn đề
Bằng chứng: transcript, tỉ lệ sửa và tỉ lệ ngắt.
- 1: chủ yếu lặp lại "fix đi", không cung cấp ngữ cảnh.
- 3: yêu cầu đọc code liên quan nhưng chưa hỏi nguyên nhân gốc.
- 5: hỏi nguyên nhân gốc, yêu cầu đọc code trước khi sửa, kiểm chứng giả thuyết trước khi chốt.

## 5. Chất lượng tài liệu
Bằng chứng: diff của `specs/` và tài liệu flow trong issue.
- 1: không cập nhật tài liệu dù flow thay đổi.
- 3: có cập nhật nhưng không ghi kiến thức ngầm vừa phát hiện.
- 5: tài liệu khớp code sau task và ghi lại kiến thức ngầm mới.
