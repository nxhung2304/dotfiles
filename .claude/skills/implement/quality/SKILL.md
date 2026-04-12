---
allowed-tools: Agent, Bash(cd *), Bash(flutter *), Bash(dart *), Bash(rubocop *), Bash(rails *)
description: Quality checks và fix lỗi.
---

1. Check code
- Flutter
    - Chạy `flutter analyze`
    - Nếu có lỗi → gọi **error-fixer** subagent
    - Chạy `flutter test`
- Rails
    - Chạy `rubocop`
    - Nếu có lỗi → gọi **error-fixer** subagent
    - Chạy `rails test`

- Verify 0 warnings/errors trước khi tiếp tục
- Trả summary: kết quả analyze/test + files đã fix
