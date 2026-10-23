---
name: script-writing
description: Viết kịch bản video ~10 phút cho kênh YouTube Tí Ớt (dự án /Users/rightsvn-hunga/Dev/personal/youtube-channel), lưu vào videos/<số>-<slug>/kich-ban.md. Dùng khi người dùng nói "viết kịch bản", "làm video về ...", "chọn ý tưởng số ...", "viết script", hoặc chọn một ý tưởng trong trend-scanner/ideas.md.
---

# Viết kịch bản video

Mục tiêu: kịch bản có số liệu kiểm chứng được và góc nhìn riêng, không phải bản lặp khuôn. YouTube không cho kiếm tiền với nội dung "mass-produced, generic, repetitive" hoặc "templated storylines", nên mỗi video phải có lập luận riêng.

## Bước 1: Chốt đề bài
1. Đọc ý tưởng người dùng chọn trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/ideas.md` và báo cáo mới nhất trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/reports/`.
2. Đọc phần định vị kênh trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/CLAUDE.md` (nếu có) để giữ đúng góc nhìn của kênh.
3. Tìm các video đã có về cùng chủ đề trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/data/videos_*.csv`. Ghi ra họ đã nói gì, để kịch bản này nói **điều khác** (một câu hỏi họ bỏ qua, một con số họ không có, một kết luận ngược lại).
4. Chọn style trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/plan/quy-tac/` (xem danh sách trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/plan/quy-tac/chung.md`). Chưa có style hợp thì báo người dùng, không tự ép vào style có sẵn.
5. Ghi tiêu đề dự kiến, dòng **Style:**, góc nhìn riêng trong 1 câu, 3–5 câu hỏi kịch bản sẽ trả lời vào `/Users/rightsvn-hunga/Dev/personal/youtube-channel/videos/<số>-<slug>/plan.md` (tạo mới nếu chưa có, trạng thái "chờ duyệt hướng"). Báo người dùng và chờ đồng ý rồi mới viết; khi được duyệt, đổi trạng thái và cập nhật file này sau mỗi bước (nghiên cứu, kịch bản).

## Bước 2: Học cách làm và nghiên cứu số liệu
- Làm theo mục "Quy trình trước khi lên kịch bản" trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/plan/quy-tac/chung.md` (lấy và đọc phụ đề ít nhất 3 video, ghi vào `/Users/rightsvn-hunga/Dev/personal/youtube-channel/plan/tham-khao.md`).
- Tìm giá bán, giá vốn, mặt bằng, nhân công, số lượng bán… từ nguồn thật: báo, số liệu thống kê, sàn thương mại điện tử, bảng giá công khai, số liệu người dùng tự thu thập.
- Mỗi số ghi lại nguồn, link, ngày xem. Không tìm được thì tự tính và ghi rõ cách tính, đánh dấu "ước tính".
- Không bịa số. Số không có nguồn cũng không tính được thì bỏ, hoặc nói khoảng ("vài chục nghìn") và ghi "ước tính".
- Nếu nói về một thương hiệu có tên thật: chỉ dùng số liệu công khai, gọi phần tự tính là ước tính, không khẳng định lãi/lỗ của họ như sự thật.

## Bước 3: Viết
Theo `/Users/rightsvn-hunga/Dev/personal/youtube-channel/plan/quy-tac/chung.md`, `kich-ban.md` của style đã chọn (khung nhịp, giọng, độ dài, chia cảnh) và định dạng file trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/ech-pipeline/CLAUDE.md` (số viết bằng chữ khi dễ đọc sai, có `<!-- prompt ảnh: ... -->`).

## Bước 4: Tự kiểm tra trước khi giao
- [ ] Mọi con số trong lời đọc đều có dòng `<!-- nguồn | ... -->` hoặc `<!-- ước tính | ... -->` ở cuối file.
- [ ] Không có ký hiệu hay link trong lời đọc.
- [ ] Không chép câu, tiêu đề, nhân vật của kênh khác.
- [ ] Góc nhìn riêng ở Bước 1 thực sự có trong kịch bản, ở nhịp mấu chốt của style.
- [ ] Đọc thử bằng `cd /Users/rightsvn-hunga/Dev/personal/youtube-channel/ech-pipeline && python make_video.py ../videos/<số>-<slug>/kich-ban.md --test`, rồi `python kiem_tra.py ../videos/<số>-<slug>/kich-ban.md --style <style>`; chỉ số nào lệch ngưỡng thì sửa hoặc báo lý do cho người dùng.

Lưu kịch bản vào `/Users/rightsvn-hunga/Dev/personal/youtube-channel/videos/<số>-<slug>/kich-ban.md`. Báo người dùng: đường dẫn file, thời lượng, các số đang là "ước tính" để họ kiểm tra lại. Sau khi video đăng, đánh dấu [x] ý tưởng trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/ideas.md`.
