# AI metrics cho Claude Code

## Cài đặt
Chạy `scripts/install/ai.sh` (link `.claude/hooks/ai_track.py` vào `~/.claude/hooks/`). Hooks đã khai báo trong `.claude/settings.json`. Gõ `/hooks` trong Claude Code để kiểm tra. Dữ liệu ghi ở `~/.ai-metrics/`.

## Task được nhận diện thế nào (ưu tiên từ cao xuống)
1. Claude đọc/sửa file trong `specs/<folder>/` → task = số issue trong tên folder (`specs/42-login/` → `42`)
2. Prompt nhắc `specs/42`, `#42`, `issue-42`
3. Tên branch có số (`feat/42-login`)
4. Không có tín hiệu → kế thừa task của turn trước cùng session

## Xem báo cáo
```bash
python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --days 30          # tất cả dự án
python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --project myapp --gh   # kèm trạng thái issue (cần gh CLI)
python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --csv report.csv   # xuất CSV để đưa lên Sheets/Notion
python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --html ~/.ai-metrics/report.html && open ~/.ai-metrics/report.html
```

Rubric chấm kỹ năng: `rubric.md`.

## Ý nghĩa cột
- `turns`: số lượt prompt để làm task
- `first_pass`: ✓ nếu không có prompt sửa và không bị Esc lần nào
- `correction_rate`: tỉ lệ prompt chứa từ sửa sai (sai, sửa lại, làm lại, wrong, revert…) — heuristic, chỉnh `CORRECTION_RE` theo cách bạn hay nói
- `interrupt_rate`: tỉ lệ turn bị ngắt (có prompt mới mà turn trước chưa có Stop)
- `claude_min`: thời gian Claude thực sự chạy; `you_min`: thời gian bạn review giữa các turn (mỗi khoảng tối đa 10 phút, tmux treo không bị tính)
- `commits`: số commit có `#<issue>` trong message
- Lỗi của hook (nếu có) ghi ở `~/.ai-metrics/errors.log`, không bao giờ làm hỏng phiên Claude Code
