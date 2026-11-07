# Design — Luật thiết kế

> Lưu tại `specs/rules/design.md`. Không ghi giá trị ở đây: giá trị nằm trong `specs/designs/tokens.css`.

## Phong cách
- Hướng đã chọn (tên 2–4 chữ):
- Cảm giác:
- Tham khảo đã dùng (và lấy gì từ đó, vì sao):

## File design của dự án
- `specs/designs/tokens.css` — mọi giá trị (màu sáng/tối, chữ, khoảng cách, bo góc, đổ bóng)
- `specs/designs/components.css` — class component, chỉ dùng `var(--...)`
- `specs/designs/components.html` — mẫu mọi component và trạng thái
- Màn hình mới: `specs/designs/<tên-màn-hình>.html`, link `tokens.css` và `components.css`, không đặt giá trị mới
- Nguồn gốc: <`tokens.css` (dự án mới) | code app, `tokens.css` chỉ phản ánh lại và phải sửa cùng lúc khi app đổi style (app đã có)>
- Flutter: so `tokens.css` với `AppColors` qua agent `design-checker`; bên sai là bên không phải nguồn gốc

## Component
<!-- tên — class — khi nào dùng / không dùng -->
- Nút chính — `.btn .btn-primary` — một hành động chính mỗi màn
-

## Luôn làm
- Mỗi màn hình có trạng thái loading, rỗng, lỗi
- Vùng bấm tối thiểu 44×44px
- Tương phản chữ tối thiểu 4.5:1
- HTML tương tác được: click chuyển màn, mở/đóng modal, đổi trạng thái

## Không làm
- Gradient tím/xanh mặc định
- Card bo góc lớn cho mọi thứ
- Emoji thay icon
- Lorem ipsum
- Mã màu, px lạc ngoài `tokens.css`
-

## Giả định
<!-- token — giá trị lấy từ đâu — cách kiểm (chạy app, tài liệu framework) -->

## Nhật ký quyết định
<!-- ngày — quyết định — lý do -->
