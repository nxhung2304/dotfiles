# Rules Index (Pre-computed for Fast Lookup)

## Usage
Import this file first to get keyword→rule mappings, then read only relevant sections.

**Token savings: ~80-85%** vs reading full files.

---

## Keyword Map (Global Rules)

| Keyword | File | Section | Lines |
|---------|------|---------|-------|
| **parser, grammar, language** | coding-rules.md | Follow Existing Codebase | 25-40 |
| **function, method, size** | clean-code.md | Function Size | 259-294 |
| **naming, name, variable** | clean-code.md | Meaningful Names | 155-200 |
| **single, responsibility, split** | clean-code.md | Single Responsibility | 200-231 |
| **dry, repeat, duplicate** | clean-code.md | DRY | 231-259 |
| **guard, early, return** | clean-code.md | Return Early | 90-124 |
| **magic, number, constant** | clean-code.md | Magic Numbers | 31-61 |
| **string, hardcoded, text** | clean-code.md | Hardcoded Strings | 61-90 |
| **indent, space, format** | code-style.md | Indentation | 32-62 |
| **line, length, wrap** | code-style.md | Line Length | 62-76 |
| **blank, line, separate** | code-style.md | Blank Lines | 98-127 |
| **condition, if, format** | code-style.md | Condition Formatting | 205-232 |
| **flutter, widget, state** | flutter/flutter.md | Widgets | 1-10 |
| **const, constructor** | flutter/flutter.md | Widgets | 5-6 |
| **layer, architecture** | core.md | Universal Principles | 3-9 |
| **small, function, generate** | coding-rules.md | Generate Small Functions | 68-102 |
| **pattern, predictable** | coding-rules.md | Prefer Predictable Patterns | 40-68 |
| **clarity, cleverness** | coding-rules.md | Core Principles | 10-25 |
| **refactor, extract, method** | refactoring.md | When to Refactor | 3-6 |

---

## Quick Reference by Category

### Structure & Architecture
- Clean Architecture layers → `core.md:3-9`
- Single Responsibility → `clean-code.md:200-231`
- DRY → `clean-code.md:231-259`

### Functions & Methods
- Size limits (20-30 lines) → `coding-rules.md:68-102`, `clean-code.md:259-294`
- Guard clauses → `clean-code.md:90-124`
- Early return → `code-style.md:127-183`

### Naming & Constants
- Magic numbers → `clean-code.md:31-61`
- Meaningful names → `clean-code.md:155-200`
- Hardcoded strings → `clean-code.md:61-90`

### Formatting
- Indentation → `code-style.md:32-62`
- Line length → `code-style.md:62-76`
- Blank lines → `code-style.md:98-127`
- Guard clause spacing → `code-style.md:127-156`

### Flutter Specific
- Const constructors, widget rules → `flutter/flutter.md:5-10`
- Extract formatters/constants → `flutter/flutter.md:12-89`

### AI Code Generation
- Follow existing patterns → `coding-rules.md:25-40`
- Prefer predictable patterns → `coding-rules.md:40-68`
- Clarity over cleverness → `coding-rules.md:10-25`

### Refactoring
- When to refactor → `refactoring.md:3-6`
- Extract shared logic → `refactoring.md:6-89`

---

## File Statistics
- `core.md`: 15 lines (always loaded, ngôn ngữ-agnostic)
- `general/clean-code.md`: ~610 lines
- `general/code-style.md`: ~470 lines
- `general/coding-rules.md`: ~440 lines
- `general/refactoring.md`: ~90 lines
- `flutter/flutter.md`: ~90 lines (chỉ load khi project là Flutter/Dart)

## Token Optimization
- Reading full files: ~15k tokens
- Reading targeted sections: ~2-3k tokens
- Using this index: ~500 tokens + targeted reads

**Savings: ~80-85% reduction**

---

## Project-Specific Rules (specs/rules/)

Flutter/Dart project rules được load từ `specs/rules/` trong project root:
- **flutter.md** → Flutter best practices, widget rules
- **clean-architecture.md** → Kiến trúc lớp, dependency rule
- **folder-structure.md** → Cấu trúc thư mục dự án
- **widgets.md** → Widget extraction, composition
- **design.md** → Colors, design tokens sync

> **Note:** `general/` chứa rule ngôn ngữ-agnostic (áp dụng mọi ngôn ngữ). `flutter/` chứa rule riêng cho Flutter/Dart, chỉ load khi project hiện tại dùng Flutter. Thêm folder tương tự (vd: `rails/`) khi cần rule riêng cho ngôn ngữ/framework khác.
