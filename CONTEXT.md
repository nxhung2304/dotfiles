# AI Usage Metrics — Context bàn giao

> File này tóm tắt cuộc thảo luận trên Claude app. Claude Code: đọc hết file này, đối chiếu với **skills global + rules hiện có** của tôi, rồi **đề xuất kế hoạch trước khi code**. Không tự triển khai ngay.

## 1. Mục tiêu

Đo lường **trình độ sử dụng AI của chính tôi** (cá nhân, chưa mở rộng cho team) để tự cải thiện. Hai lớp:
- **Lớp số liệu**: AI giúp tôi làm task hiệu quả đến đâu (tự động qua hooks).
- **Lớp kỹ năng**: tôi kiểm soát và hiểu output của AI đến đâu (AI chấm theo rubric + quiz).

Nguyên tắc: đo theo **kết quả**, không theo số dòng code hay thời gian session. Code nhiều, tốn nhiều chưa chắc có giá trị.

## 2. Quy ước làm việc hiện tại

- Dùng **Claude Code CLI**, thường chạy trong **tmux** (session có thể treo nhiều ngày).
- Mỗi dự án có thư mục `specs/`. **Mỗi GitHub issue = 1 folder** `specs/<issue>/` chứa các file .md cho task đó.
- Đã có một số skills riêng cho công việc.
- Commit message nên có `#<issue>`.

## 3. Đã làm xong (các file đi kèm)

- `ai_track.py`: một script cho mọi hook, ghi vào `~/.ai-metrics/metrics.db` (SQLite). Luôn exit 0, lỗi ghi vào `~/.ai-metrics/errors.log`.
- `ai_report.py`: báo cáo dạng text/CSV theo task và theo skill. Có `--days`, `--project`, `--gh`, `--csv`.
- `settings.hooks.json`: cấu hình hooks UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop.
- `README.md`: cách cài và ý nghĩa các cột.

**Thiết kế đã chốt:**
- Đơn vị đo là **turn** và **task**, không phải session.
- Thời gian Claude chạy = Stop − UserPromptSubmit. Thời gian của tôi = Stop → prompt kế, **mỗi khoảng tối đa 10 phút** (bỏ idle của tmux).
- Bị ngắt (Esc) = có prompt mới mà turn trước không có Stop.
- Nhận diện task theo thứ tự ưu tiên: Claude đụng file trong `specs/<folder>/` → prompt nhắc `specs/42` / `#42` → số trong tên branch → kế thừa turn trước cùng session. Folder `42-login` được chuẩn hoá thành `42`.
- Nhận diện skill: tool `Skill` hoặc đọc file `skills/<tên>/SKILL.md`.
- Token lấy từ transcript JSONL, dedupe theo message id, tính chênh lệch giữa các lần Stop.

**Cần kiểm tra lại với phiên bản Claude Code hiện tại:**
- Tên event `PostToolUseFailure` và các field trong input của hook.
- Field tên skill khi tool_name là `Skill` (đang đoán: `skill` / `name` / `command`).
- `CORRECTION_RE` (nhận diện prompt sửa sai) là heuristic, cần chỉnh theo cách tôi hay nói.

## 4. Các chỉ số số liệu

Theo từng issue: số turn, đúng ngay lần đầu, tỉ lệ sửa, tỉ lệ ngắt, tỉ lệ tool fail, thời gian Claude chạy, thời gian tôi review, token, số commit có `#issue`, trạng thái issue (qua `gh`), skills đã dùng.
Theo skill: so sánh task có skill và không có skill (turn TB, tỉ lệ sửa, tỉ lệ ngắt, % đúng ngay lần đầu).

**Chưa làm, dự định thêm:**
- **Code survival**: code AI viết còn giữ nguyên sau N ngày hay bị sửa/revert (git blame/diff).
- **% code AI viết**: dòng Claude sửa qua Edit/Write so với diff commit cuối.
- **Bug trên LOC**: issue bug ghi `regression from #42` để gắn ngược về task gốc. Mục tiêu tham khảo < 1 bug / 2000 dòng.
- **Token chuẩn hoá**: token / số dòng thay đổi, tỉ lệ cache hit.

## 5. Các tiêu chí kỹ năng (lấy ý từ thảo luận trên VOZ)

1. **Kiểm soát output / đánh giá phương án**: có yêu cầu nhiều phương án, so ưu nhược, phản biện AI, biết vì sao chọn. Bằng chứng: transcript + file `specs/<issue>/decision.md`.
2. **Kiểm soát code**: không có code rác, flow clean, tỉ lệ bug thấp, hiểu code trước khi bàn giao. Bằng chứng: bug/LOC, code survival, điểm `/ai-quiz`.
3. **Cách tìm hiểu vấn đề**: đọc code, hỏi nguyên nhân gốc, hay chỉ lặp "fix đi". Bằng chứng: transcript + tỉ lệ sửa/ngắt.
4. **Kiến thức phát triển sau task**: hiểu bản chất, lý do chọn, rủi ro. Bằng chứng: `/ai-quiz` + `specs/<issue>/learnings.md` do **tôi tự viết, không nhờ AI**.
5. **Tiết kiệm token**: dùng tài liệu làm ngữ cảnh, câu hỏi tập trung. Bằng chứng: token chuẩn hoá, cache hit, có dùng `specs/` hay giải thích lại từ đầu.
6. **Chất lượng tài liệu** (bổ sung): mỗi task có cập nhật tài liệu flow / ghi lại kiến thức ngầm vừa phát hiện không.

**Yêu cầu khi AI chấm (tiêu chí 1, 3, 4, 6):** rubric cố định, thang 1–5, mỗi mức mô tả rõ, **bắt buộc trích bằng chứng** từ transcript/file. AI không tự tính số; số liệu do script tính sẵn.

## 6. Phân tầng module theo rủi ro

Kết luận từ thảo luận: mức độ cần hiểu code phụ thuộc domain. Domain của tôi AI vẫn sinh technical bug và có nhiều kiến thức chưa được ghi lại, nên module quan trọng vẫn phải review đến từng dòng.
- **critical** (nghiệp vụ lõi, nhiều kiến thức ngầm, từng có bug do AI): `/ai-quiz` hỏi đến từng dòng, chấm tiêu chí 2 khắt khe.
- **normal**: chỉ hỏi flow và quyết định thiết kế.
- Cách đánh dấu: `tier: critical` trong `specs/<issue>/` hoặc một file liệt kê đường dẫn critical cho mỗi repo. **Chưa chốt.**

## 7. Kiến trúc đích

- **Hooks** (đã có): thu số liệu.
- **Skill `/ai-quiz`** (tương tác, chạy tay trước khi bàn giao): chọn ngẫu nhiên đoạn code trong diff + câu hỏi kiểu tech lead (bản chất, vì sao chọn, rủi ro). Độ sâu theo tier. Điểm ghi vào DB.
- **Skill `ai-review`** + **cron hàng tuần** chạy Claude Code headless:
  1. Script tính số liệu, xuất JSON.
  2. Claude chấm 6 tiêu chí cho các issue đóng trong tuần theo rubric, có thể mở `specs/<issue>/` và transcript của task tệ nhất để tìm nguyên nhân. Ghi điểm ra JSON.
  3. Script render **HTML mở trên trình duyệt** có chart.
- **Nội dung báo cáo tuần**: tổng quan so với tuần trước, xu hướng 4–8 tuần, điểm 6 tiêu chí, bảng hiệu quả skill, top 3 task tốn công kèm nguyên nhân, **1–2 việc cần làm tuần tới**.
- Cần tracking ít nhất 2–4 tuần trước khi tin vào kết luận. So sánh skill cần ≥ 5 task mỗi skill, ít hơn thì ghi "chưa đủ dữ liệu".

## 8. Lưu ý

- Định luật Goodhart: đây là công cụ tự cải thiện, không tối ưu cho điểm số.
- Transcript chứa code và dữ liệu dự án, chỉ xử lý local.
- Sau này có thể mở rộng cho team (đẩy log về chỗ chung, DORA metrics), nhưng hiện tại chỉ làm cá nhân.

## 9. Việc tiếp theo cho Claude Code

1. Đọc file này, các file code đi kèm, skills global và rules của tôi. Chỉ ra chỗ trùng lặp hoặc xung đột.
2. Xác minh các điểm ở mục 3 "Cần kiểm tra lại".
3. Đề xuất **rubric chấm 6 tiêu chí** để tôi duyệt trước.
4. Đề xuất cách đánh dấu tier (mục 6).
5. Sau khi tôi duyệt mới triển khai: `/ai-quiz`, `ai-review`, HTML report, cron.
