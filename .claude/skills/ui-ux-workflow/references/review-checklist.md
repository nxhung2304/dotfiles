# Checklist review

Tự kiểm trước khi đưa người dùng. Ghi ngắn gọn mục nào đạt, mục nào đã sửa.

## Đúng vấn đề
- [ ] Việc chính (trong context dự án) làm được trong ít bước nhất
- [ ] Hành động chính nổi bật nhất trên màn hình
- [ ] Thứ tự thông tin theo mức quan trọng với người dùng

## Trạng thái
- [ ] Loading
- [ ] Rỗng (lần đầu dùng, không có kết quả) — có hướng dẫn bước tiếp theo
- [ ] Lỗi — nói rõ chuyện gì và cách khắc phục
- [ ] Dữ liệu dài/xấu: tên rất dài, số lớn, danh sách 100 mục

## Responsive và nền tảng
- [ ] Mobile ~390px, tablet, desktop
- [ ] Không cuộn ngang ngoài ý muốn
- [ ] Dark mode dùng đúng token

## Accessibility
- [ ] Tương phản chữ ≥ 4.5:1
- [ ] Vùng bấm ≥ 44×44px
- [ ] Có focus state khi dùng bàn phím
- [ ] Không truyền thông tin chỉ bằng màu

## Nhất quán
- [ ] Chỉ dùng token trong `specs/designs/tokens.css` (trang lẻ: `:root` của file), không mã màu hay px lạc
- [ ] Chỉ dùng component trong `specs/designs/components.css`; component mới đã được duyệt và thêm vào bộ design
- [ ] Tương tác được: click chuyển màn, modal/menu/tab hoạt động, đổi được trạng thái loading/rỗng/lỗi
- [ ] Không vi phạm mục "Không làm" trong `specs/rules/design.md`
- [ ] Cùng loại phần tử thì cùng kiểu

## Không generic
- [ ] Có ít nhất một lựa chọn thị giác riêng cho dự án này (chữ, màu, bố cục)
- [ ] Nội dung thật, không lorem ipsum
