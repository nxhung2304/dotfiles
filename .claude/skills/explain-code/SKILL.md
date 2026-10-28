---
name: explain-code
description: Giải thích code, flow logic hoặc khái niệm lập trình ở bất kỳ ngôn ngữ/framework nào theo một khung nhất quán, dễ hiểu và có kiểm tra mức độ hiểu.
---

# Explain Code

Dùng skill này khi người dùng nhờ giải thích một đoạn code, một file, một flow xử lý, một lỗi, hoặc một khái niệm lập trình. Áp dụng cho mọi ngôn ngữ và framework.

## Nguyên tắc chung

- Trả lời bằng ngôn ngữ người dùng đang dùng (mặc định tiếng Việt). Giữ nguyên thuật ngữ kỹ thuật tiếng Anh, giải thích ngắn khi thuật ngữ xuất hiện lần đầu.
- Chỉ giải thích dựa trên code thật. Nếu thiếu ngữ cảnh (hàm được gọi ở file khác, config, version thư viện), nói rõ đang thiếu gì và đây là suy luận, hoặc đọc thêm file nếu có quyền truy cập (ví dụ trong Claude Code).
- Không bịa API hay hành vi của thư viện. Nếu không chắc, nói rõ và gợi ý kiểm tra tài liệu chính thức đúng phiên bản.
- Ưu tiên giải thích "tại sao", không chỉ "cái này làm gì".
- Mặc định ngắn gọn, đủ ý. Nếu người dùng nói "chi tiết", "đào sâu", "line by line" thì mở rộng.

## Bước 0: Xác định bối cảnh

Trước khi giải thích, tự nhận diện (không cần hỏi nếu nhìn code là biết):
- Ngôn ngữ, framework, phiên bản nếu thấy được.
- Loại yêu cầu: giải thích đoạn code / flow nhiều file / lỗi / khái niệm.
- Trình độ người hỏi (dựa vào cách hỏi). Nếu không rõ, giải thích ở mức developer có kinh nghiệm cơ bản.

## Khung trả lời

### 1. Tóm tắt một câu
Đoạn code này làm gì, ở vai trò nào trong hệ thống.

### 2. Flow tổng thể
- Mô tả các bước chính theo thứ tự: input → xử lý → output / side effect.
- Nếu có từ 3 nhánh/bước trở lên, hoặc có async, callback, event, gọi qua nhiều layer: vẽ sơ đồ (Mermaid flowchart hoặc sequenceDiagram; nếu môi trường không render được thì dùng sơ đồ text đơn giản).

### 3. Giải thích các phần quan trọng
- Chia theo khối logic, không nhất thiết từng dòng (trừ khi được yêu cầu).
- Với mỗi khối: làm gì, tại sao cần, phụ thuộc vào cái gì.
- Trích dẫn đúng dòng/đoạn code đang nói tới.
- Giải thích các pattern hoặc cú pháp đặc thù của ngôn ngữ/framework (ví dụ: decorator, hook, generic, middleware, dependency injection, ORM query, lifetime...).

### 4. Edge case và điểm dễ lỗi
- Input rỗng/null, lỗi mạng, race condition, xử lý exception, hiệu năng, bảo mật (injection, lộ dữ liệu, auth).
- Chỉ nêu những điểm thực sự liên quan, không liệt kê cho có.

### 5. Lựa chọn thiết kế (khi đáng nói)
- Có cách viết khác không, đánh đổi là gì.
- Nếu thấy bug hoặc code smell rõ ràng, chỉ ra kèm cách sửa ngắn gọn.

### 6. Cách tự kiểm chứng
Gợi ý 1–2 cách người dùng tự xác nhận hiểu đúng: đặt breakpoint ở đâu, log biến nào, chạy test/input nào.

### 7. Kiểm tra mức độ hiểu
Đặt 2–3 câu hỏi ngắn (ví dụ: "Nếu bỏ dòng X thì chuyện gì xảy ra?"). Không đưa đáp án ngay; chỉ đưa khi người dùng trả lời hoặc yêu cầu.

## Trường hợp đặc biệt

- **Giải thích lỗi**: nói lỗi nghĩa là gì → nguyên nhân khả dĩ nhất dựa trên code → cách sửa → cách tránh lần sau.
- **Giải thích khái niệm**: định nghĩa ngắn → ví dụ code tối giản trong ngôn ngữ người dùng đang dùng → khi nào nên/không nên dùng.
- **Flow nhiều file / cả project**: bắt đầu từ entry point, đi theo đường request/data, liệt kê file theo thứ tự được gọi, sau đó mới đi vào chi tiết.
- **Người dùng tự giải thích lại**: xác nhận phần đúng, chỉ rõ phần sai hoặc thiếu, không viết lại toàn bộ.

## Không làm

- Không lặp lại nguyên đoạn code dài chỉ để chú thích.
- Không giải thích những dòng hiển nhiên (import, khai báo biến đơn giản) trừ khi được hỏi.
- Không tự ý refactor hay sửa code khi người dùng chỉ nhờ giải thích; chỉ đề xuất.

