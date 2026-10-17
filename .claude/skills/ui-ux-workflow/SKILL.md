---
name: ui-ux-workflow
description: Quy trình thiết kế UI/UX có nghiên cứu cho vibe coding — hiểu vấn đề, tra cứu tham khảo thật (Mobbin, Refero, Land-book, Dribbble), chốt design token, dựng prototype bằng Claude Design, xuất HTML, review và lặp feedback. Dùng skill này bất cứ khi nào người dùng muốn thiết kế, dựng, mockup, prototype hoặc làm lại giao diện/màn hình/landing page/app/web/dashboard, hỏi "làm UI cho…", "thiết kế màn hình…", "UI trông generic quá", hoặc cần tham khảo thiết kế — kể cả khi họ không nhắc chữ "UI/UX". Also use for English requests to design, mock up, prototype or redesign any app or web interface.
---

# UI/UX Workflow

Mục tiêu: giao diện **đúng** (giải quyết việc của người dùng) trước, rồi mới **đẹp** (không generic). AI dễ cho ra UI na ná nhau vì thiếu bối cảnh và thiếu tham khảo thật — skill này bù hai thứ đó.

Quy trình gồm 7 bước. Bước 0 quyết định chạy những bước nào.

## Nơi lưu file (dùng đúng các chỗ này, không tạo file ở root dự án)

| Nội dung | Đặt ở |
|---|---|
| Prototype HTML và **token** (CSS variables ở `:root`) — nguồn sự thật của token | `specs/designs/<tên-màn-hình>.html` |
| Luật thiết kế ("Luôn làm" / "Không làm"), tham khảo đã dùng, nhật ký quyết định | `specs/rules/design.md` (mẫu: `assets/design.template.md`) |
| Context sản phẩm (người dùng, việc chính, nền tảng, ràng buộc) | `CLAUDE.md` của dự án hoặc `specs/story.md` nếu đã có; chỉ khi chưa có chỗ nào chứa mới tạo `specs/project.md` (mẫu: `assets/project.template.md`) |

Không lưu token ở hai nơi: token nằm trong HTML, `specs/rules/design.md` chỉ liệt kê luật và trỏ tới file HTML. Dự án Flutter: sau khi chốt token, nhờ agent `design-checker` so HTML với `AppColors` và đề xuất cập nhật (nó chỉ đề xuất, không tự sửa).

Mọi lần ghi vào các file trên: đề nghị với người dùng trước, không tự ghi.

---

## Bước 0 — Chọn chế độ

Hỏi một câu (nếu chưa rõ từ ngữ cảnh), rồi chọn:

| Chế độ | Khi nào | Chạy các bước |
|---|---|---|
| **Nhanh** | Landing page, tool nội bộ, thử ý tưởng, 1 màn hình | 1 (rút gọn) → 3 → 4 → 5 |
| **Chuẩn** | Sản phẩm mới, nhiều màn hình chính | 1 → 2 → 3 → 4 → 5 → 6 |
| **Mở rộng** | Sản phẩm đã có brand/design system | 1 → 2 (chỉ cho pattern mới) → 3 (chỉ đọc token có sẵn) → 4 → 5 → 6 |

Nếu người dùng chỉ nói một câu ngắn và không trả lời, mặc định **Nhanh**, ghi rõ giả định.

---

## Bước 1 — Hiểu vấn đề

Nguồn context, theo thứ tự ưu tiên:
1. `CLAUDE.md` của dự án, `specs/story.md`, `specs/project.md` (cái nào có), hoặc file context người dùng đính kèm.
2. Mô tả trong chat.

Đối chiếu với các mục bắt buộc trong `assets/project.template.md`:
- Sản phẩm là gì, giải quyết vấn đề gì
- Người dùng chính là ai
- Việc quan trọng nhất họ cần làm xong (1–3 việc)
- Nền tảng: mobile app / web app / website-landing
- Brand hoặc design system có sẵn không
- Ràng buộc: tech stack, deadline, ngôn ngữ hiển thị

Chỉ hỏi phần **còn thiếu**, tối đa 2–3 câu một lượt. Không bắt điền lại từ đầu. Nếu dự án chưa có chỗ nào chứa context, gợi ý dùng mẫu `project.template.md`.

Sau đó **tóm tắt lại 2–3 câu để người dùng xác nhận** trước khi đi tiếp. Ví dụ: "Mình hiểu là app quản lý chi tiêu cho sinh viên, mobile, ưu tiên màn hình nhập khoản chi thật nhanh, chưa có brand. Đúng không?"

Ở chế độ Nhanh: nếu thiếu thông tin, tự giả định hợp lý, liệt kê giả định, làm tiếp.

Khi đã xác nhận, đề nghị lưu phần context mới vào đúng chỗ ở bảng "Nơi lưu file" để lần sau không phải hỏi lại.

---

## Bước 2 — Tra cứu tham khảo

### 2a. Kiểm tra công cụ có sẵn
Trước khi tra cứu, xem trong danh sách tool đang có:
- MCP **Mobbin** (`api.mobbin.com/mcp`)
- MCP **Refero** (`api.refero.design/mcp`, cần gói Pro)
- web search / web fetch / trình duyệt

Nếu thiếu MCP cần thiết, nói ngắn gọn và dùng phương án dự phòng (xem `references/sources.md`). Không dừng quy trình chỉ vì thiếu một nguồn.

### 2b. Chọn nguồn theo ngữ cảnh
| Ngữ cảnh | Nguồn ưu tiên |
|---|---|
| Mobile app (flow, màn hình) | Mobbin → Refero |
| Web app, SaaS, dashboard | Refero → Mobbin (web) |
| Landing page, marketing site | Land-book → Refero styles |
| Cảm hứng thị giác, minh hoạ | Dribbble (chỉ tham khảo, nhiều concept không thực tế) |

Chi tiết cách tìm và câu truy vấn mẫu: `references/sources.md`.

### 2c. Tiết kiệm lượt gọi
Mobbin và Refero có phí và giới hạn. Mỗi màn hình chính: 1–3 truy vấn cụ thể (ví dụ "onboarding finance app mobile", "pricing page monthly annual toggle web"), không quét rộng. Chế độ Nhanh: tối đa 1–2 truy vấn cho cả dự án, hoặc bỏ qua.

### 2d. Tổng hợp, không sao chép
Từ 3–6 tham khảo, rút ra:
- **Pattern**: cấu trúc màn hình, thứ tự thông tin, cách xử lý hành động chính
- **Gợi ý thị giác**: mật độ, phong cách chữ, cách dùng màu

Trình bày ngắn cho người dùng: tham khảo nào, lấy gì từ đó, vì sao hợp với context ở Bước 1. Không tái tạo nguyên thiết kế, logo, minh hoạ hay nhân vật của sản phẩm khác — mục tiêu là học pattern, kết quả phải là thiết kế của dự án này.

---

## Bước 3 — Chốt design token

Tạo (hoặc đọc, nếu chế độ Mở rộng) bộ token tối thiểu:
- Màu: nền, bề mặt, chữ chính, chữ phụ, viền, primary, trạng thái (success/warning/error) — kèm giá trị dark mode
- Chữ: font (có fallback), thang cỡ chữ, độ đậm
- Khoảng cách: thang 4 hoặc 8
- Bo góc, đổ bóng

Token là biến CSS ở `:root` của file `specs/designs/<tên-màn-hình>.html` (khung sẵn: `assets/tokens.template.css`). Ghi vào `specs/rules/design.md` mục **"Không làm"** để chống UI generic, ví dụ: không gradient tím mặc định, không lạm dụng card bo góc lớn, không emoji làm icon.

Chế độ Mở rộng: không tự đặt token mới; đọc hệ thống có sẵn (HTML hiện có, `specs/rules/design.md`, `AppColors`), chỉ đề xuất bổ sung khi thật cần và nói rõ.

---

## Bước 4 — Dựng prototype

Thứ tự công cụ:
1. **Claude Design** (hoặc Design artifact type nếu môi trường có) — tốt nhất vì người dùng sửa trực tiếp trên canvas.
2. Nếu không có: một file HTML tự chứa (CSS/JS inline), dùng token ở Bước 3.

Nguyên tắc khi dựng:
- Làm **màn hình quan trọng nhất trước** (việc chính ở Bước 1), không dựng hết một lúc.
- Mỗi màn hình có đủ trạng thái: mặc định, loading, rỗng, lỗi.
- Responsive từ đầu; mobile app thì khung ~390px.
- Dùng nội dung thật hoặc gần thật (tiếng Việt nếu sản phẩm cho người Việt), không lorem ipsum.
- Chế độ Chuẩn: có thể đưa 2 hướng khác nhau rõ rệt để người dùng chọn, rồi mới đi sâu một hướng.

---

## Bước 5 — Xuất HTML và review

Xuất HTML từ prototype vào `specs/designs/<tên-màn-hình>.html`, rồi tự review theo `references/review-checklist.md` **trước** khi đưa người dùng. Sửa các lỗi tìm được, rồi báo ngắn gọn những gì đã kiểm tra.

Khi xin feedback, hỏi có định hướng thay vì "thấy sao?":
- Việc chính có làm được trong ít bước nhất chưa?
- Cảm giác tổng thể có đúng ý (ví dụ "tin cậy", "vui", "chuyên nghiệp")?
- Màn hình nào cần sửa trước?

### Vòng lặp và điểm dừng
- Mỗi vòng: ghi feedback → sửa đúng phần được góp ý (không làm lại cả trang) → xuất lại.
- Thống nhất điểm dừng từ đầu: ai duyệt, và "xong" nghĩa là gì (ví dụ: đạt checklist + người dùng chốt màn hình chính).
- Sau 3 vòng mà vẫn lệch hướng: quay lại Bước 1 kiểm tra context, đừng tiếp tục chỉnh màu/khoảng cách.

---

## Bước 6 — Handoff sang code thật

HTML prototype thường không dùng thẳng được trong dự án. Khi người dùng sẵn sàng code:
1. Xác nhận tech stack (React/Next, Vue, Flutter, SwiftUI…) và thư viện component (shadcn/ui, MUI…).
2. Chuyển token từ `:root` của HTML sang định dạng của stack (Tailwind config, CSS variables, theme file; Flutter: `AppColors` — dùng agent `design-checker` để so khớp).
3. Liệt kê component cần có, map sang component có sẵn của thư viện; chỉ tự viết cái thiếu.
4. Ghi các quyết định UX (trạng thái, luồng, edge case) vào `specs/rules/design.md` hoặc file spec của issue để không bị mất khi code.

---

## Bước 7 — Ghi nhận bài học

Kết thúc dự án (hoặc một đợt lớn), đề nghị cập nhật:
- `specs/rules/design.md`: mục "Không làm" mới, nhật ký quyết định
- Token đã chỉnh: sửa trong file HTML, không chép sang chỗ khác
- Context mới phát sinh: vào `CLAUDE.md` / `specs/story.md` / `specs/project.md` (nơi đang chứa context)

Đây là cách workflow tốt dần theo thời gian.

---

## File đi kèm
- `assets/project.template.md` — mẫu context dự án, chỉ dùng khi dự án chưa có chỗ chứa context.
- `assets/design.template.md` — mẫu `specs/rules/design.md` (luật, tham khảo, nhật ký).
- `assets/tokens.template.css` — khung token để dán vào `:root` của HTML prototype.
- `references/sources.md` — cách dùng từng nguồn tham khảo, truy vấn mẫu, phương án dự phòng. Đọc ở Bước 2.
- `references/review-checklist.md` — checklist review. Đọc ở Bước 5.
