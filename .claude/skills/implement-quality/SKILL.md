---
name: implement-quality
allowed-tools: Agent, Bash(cd *), Bash(flutter *), Bash(dart *), Bash(rubocop *), Bash(rails *), Bash(mvn *), Bash(npm *), Bash(python *), Bash(make *), Bash(cargo *)
description: Quality checks and error fixing.
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
    - Run `flutter analyze`
    - If errors → call the **error-fixer** subagent
    - Run `flutter test`
- Rails
    - Run `rubocop`
    - If errors → call the **error-fixer** subagent
    - Run `rails test`
- Neovim plugin (Lua)
    - Run `lua-language-server` check if available
    - Run tests if present (busted, plenary)
- Node.js
    - Run `npm test` or `npm run lint`
- Python
    - Run `pytest` or `black --check`
- Rust
    - Run `cargo clippy`
    - Run `cargo test`

- Verify 0 warnings/errors before continuing

**IMPORTANT:** Do NOT report a summary to the user — only return the result so the orchestrator can continue to the next step.
Return: { tests_passed, files_fixed, warnings }
