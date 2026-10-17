# Nguồn tham khảo

## Mobbin
- **Mạnh nhất:** màn hình và flow của app thật, cả mobile và web.
- **Kết nối:** MCP chính thức, remote, đăng nhập OAuth: `https://api.mobbin.com/mcp`
- **Truy vấn tốt:** cụ thể theo loại màn hình + ngành + nền tảng.
  - "onboarding flow fintech mobile"
  - "empty state task list iOS"
  - "checkout flow e-commerce web"
- **Lưu ý:** có giới hạn theo gói, nên truy vấn có chủ đích.

## Refero
- **Mạnh nhất:** web app/SaaS; có 3 lớp: styles (hệ thống thị giác), screens, flows.
- **Kết nối:** MCP `https://api.refero.design/mcp`, cần gói Pro (có hạn mức lượt gọi mỗi tháng).
- **Truy vấn tốt:**
  - styles: "developer tool website minimal dark"
  - screens: "pricing page monthly annual toggle web"
  - flows: "subscription cancellation with retention offer"
- **Mẹo:** dùng lớp styles để gợi ý token ở Bước 3.

## Land-book
- **Mạnh nhất:** landing page, marketing site.
- **Kết nối:** không có MCP chính thức (tại thời điểm viết). Dùng web search / web fetch / trình duyệt.
- **Lưu ý:** tôn trọng điều khoản trang; chỉ xem và rút pattern.

## Dribbble
- **Mạnh nhất:** cảm hứng thị giác, màu, minh hoạ, micro-interaction.
- **Kết nối:** không có MCP chính thức (tại thời điểm viết). Dùng web search / trình duyệt.
- **Lưu ý:** nhiều shot là concept chưa từng chạy thật — không dùng làm chuẩn cho UX/flow.

## Phương án dự phòng khi không có MCP nào
1. Web search với từ khoá pattern ("best onboarding examples fintech app").
2. Nhờ người dùng gửi ảnh chụp màn hình sản phẩm họ thích.
3. Dựa vào kiến thức pattern phổ biến (Apple HIG, Material Design) và nói rõ là chưa có tham khảo thực tế.

## Nguyên tắc chung
- Tham khảo để học pattern, không sao chép thiết kế, logo, minh hoạ hay thương hiệu.
- Ghi lại tham khảo đã dùng và lý do vào `specs/rules/design.md`.
