---
name: script-writing
description: Viết kịch bản video ~10 phút cho kênh YouTube Tí Ớt (dự án /Users/rightsvn-hunga/Dev/personal/youtube-channel), lưu vào ech-pipeline/scripts/. Dùng khi người dùng nói "viết kịch bản", "làm video về ...", "chọn ý tưởng số ...", "viết script", hoặc chọn một ý tưởng trong trend-scanner/ideas.md.
---

# Viết kịch bản video

Mục tiêu: kịch bản có số liệu kiểm chứng được và góc nhìn riêng, không phải bản lặp khuôn. YouTube không cho kiếm tiền với nội dung "mass-produced, generic, repetitive" hoặc "templated storylines", nên mỗi video phải có lập luận riêng.

## Bước 1: Chốt đề bài
1. Đọc ý tưởng người dùng chọn trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/ideas.md` và báo cáo mới nhất trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/reports/`.
2. Đọc phần định vị kênh trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/CLAUDE.md` (nếu có) để giữ đúng góc nhìn của kênh.
3. Tìm các video đã có về cùng chủ đề trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/data/videos_*.csv`. Ghi ra họ đã nói gì, để kịch bản này nói **điều khác** (một câu hỏi họ bỏ qua, một con số họ không có, một kết luận ngược lại).
4. Ghi tiêu đề dự kiến, góc nhìn riêng trong 1 câu, 3–5 câu hỏi kịch bản sẽ trả lời vào `/Users/rightsvn-hunga/Dev/personal/youtube-channel/plan/videos/<số>-<slug>.md` (tạo mới nếu chưa có, trạng thái "chờ duyệt hướng"). Báo người dùng và chờ đồng ý rồi mới viết; khi được duyệt, đổi trạng thái và cập nhật file này sau mỗi bước (nghiên cứu, kịch bản).

## Bước 2: Nghiên cứu số liệu
- Tìm giá bán, giá vốn, mặt bằng, nhân công, số lượng bán… từ nguồn thật: báo, số liệu thống kê, sàn thương mại điện tử, bảng giá công khai, số liệu người dùng tự thu thập.
- Mỗi số ghi lại nguồn, link, ngày xem. Không tìm được thì tự tính và ghi rõ cách tính, đánh dấu "ước tính".
- Không bịa số. Số không có nguồn cũng không tính được thì bỏ, hoặc nói khoảng ("vài chục nghìn") và ghi "ước tính".
- Nếu nói về một thương hiệu có tên thật: chỉ dùng số liệu công khai, gọi phần tự tính là ước tính, không khẳng định lãi/lỗ của họ như sự thật.

## Bước 3: Viết
Theo định dạng trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/ech-pipeline/CLAUDE.md` (25–35 cảnh, mỗi cảnh 2–5 câu, số viết bằng chữ khi dễ đọc sai, có `<!-- prompt ảnh: ... -->`).

Bố cục gợi ý cho chủ đề tài chính (chủ đề khác thì tự dựng bố cục riêng):
1. **Mở đầu (≤ 30 giây)**: một nghịch lý hoặc con số gây tò mò, rồi hứa hẹn video sẽ trả lời gì. Không chào hỏi dài, không giới thiệu kênh.
2. **Bóc tách doanh thu**: khách trả tiền cho gì, bao nhiêu, bao nhiêu lượt.
3. **Bóc tách chi phí**: cố định và biến đổi.
4. **Điểm mấu chốt**: vì sao mô hình sống được (hoặc vì sao nhiều người thua). Đây là phần góc nhìn riêng, dài nhất.
5. **Rủi ro / mặt trái**.
6. **Kết**: tóm 1–2 câu và một câu hỏi để người xem bình luận.

Cứ 2–3 phút đặt một câu hỏi hoặc chuyển ý để giữ người xem.

## Bước 4: Tự kiểm tra trước khi giao
- [ ] Mọi con số trong lời đọc đều có dòng `<!-- nguồn | ... -->` hoặc `<!-- ước tính | ... -->` ở cuối file.
- [ ] Không có ký hiệu hay link trong lời đọc.
- [ ] Không chép câu, tiêu đề, nhân vật của kênh khác.
- [ ] Góc nhìn riêng ở Bước 1 thực sự có trong phần "Điểm mấu chốt".
- [ ] Đọc thử bằng `cd /Users/rightsvn-hunga/Dev/personal/youtube-channel/ech-pipeline && python make_video.py scripts/<file>.md --test`, tổng thời lượng 9–12 phút.

## Bước 5: Bảng tính cho người xem (chỉ với chủ đề tài chính)
Theo định vị "bảng tính mở", tạo `/Users/rightsvn-hunga/Dev/personal/youtube-channel/ech-pipeline/scripts/<ten-khong-dau>_bang_tinh.csv` (UTF-8 có BOM) gồm các cột `hang_muc, loai (doanh thu/chi phí), so_tien, don_vi, nguon_hoac_uoc_tinh`, khớp với số trong lời đọc, và một dòng lãi ước tính. Người dùng sẽ đưa lên Google Sheets và gắn link vào mô tả video.

Lưu kịch bản vào `/Users/rightsvn-hunga/Dev/personal/youtube-channel/ech-pipeline/scripts/<ten-khong-dau>.md`. Báo người dùng: đường dẫn file, thời lượng, các số đang là "ước tính" để họ kiểm tra lại. Sau khi video đăng, đánh dấu [x] ý tưởng trong `/Users/rightsvn-hunga/Dev/personal/youtube-channel/trend-scanner/ideas.md`.
