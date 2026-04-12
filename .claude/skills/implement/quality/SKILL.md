---
description: Quality checks và fix lỗi.
---

- Chạy `flutter analyze`
- Nếu có lỗi → gọi **error-fixer** subagent
- Chạy `flutter test`
- Verify 0 warnings/errors trước khi tiếp tục
- Trả summary: kết quả analyze/test + files đã fix
