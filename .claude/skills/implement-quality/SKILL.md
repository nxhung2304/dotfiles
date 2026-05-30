---
name: implement-quality
allowed-tools: Agent, Bash(cd *), Bash(flutter *), Bash(dart *), Bash(rubocop *), Bash(rails *), Bash(mvn *), Bash(npm *), Bash(python *), Bash(make *), Bash(cargo *)
description: Quality checks và fix lỗi.
---

1. Detect project type (check in this priority order — stop at first match)
   1. `pubspec.yaml` → Flutter
   2. `Gemfile` → Rails
   3. `go.mod` → Go
   4. `Cargo.toml` → Rust
   5. `requirements.txt` / `pyproject.toml` → Python
   6. `package.json` → Node.js
   7. `*.lua` in project root or `lua/` dir → Neovim plugin
   8. None matched → skip quality check, warn user

2. Check code
- Flutter
    - Chạy `flutter analyze`
    - Nếu có lỗi → gọi **error-fixer** subagent
    - Chạy `flutter test`
- Rails
    - Chạy `rubocop`
    - Nếu có lỗi → gọi **error-fixer** subagent
    - Chạy `rails test`
- Neovim plugin (Lua)
    - Chạy `lua-language-server` check nếu có
    - Chạy tests nếu có (busted, plenary)
- Node.js
    - Chạy `npm test` hoặc `npm run lint`
- Python
    - Chạy `pytest` hoặc `black --check`
- Rust
    - Chạy `cargo clippy`
    - Chạy `cargo test`

- Verify 0 warnings/errors trước khi tiếp tục

**IMPORTANT:** KHÔNG report summary cho user - chỉ return kết quả để orchestrator tiếp tục step tiếp theo.
Return: { tests_passed, files_fixed, warnings }
