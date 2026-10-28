# Rules Index (Pre-computed for Fast Lookup)

## Usage
Import this file first to get keyword→rule mappings, then read only relevant sections.
Line ranges are inclusive: from the section heading to the line before the next heading.

**Token savings: ~80-85%** vs reading full files.

---

## Keyword Map (Global Rules)

| Keyword | File | Section | Lines |
|---------|------|---------|-------|
| **layer, architecture, placeholder, todo** | core.md | Universal Principles | 3-9 |
| **clarity, cleverness** | coding-rules.md | Core Principles | 10-24 |
| **parser, grammar, language, existing, convention** | coding-rules.md | Follow Existing Codebase | 25-39 |
| **pattern, predictable** | coding-rules.md | Prefer Predictable Patterns | 40-67 |
| **small, function, generate** | coding-rules.md | Generate Small Functions | 68-101 |
| **over-engineering, abstraction** | coding-rules.md | Avoid Over-Engineering | 253-268 |
| **module, boundary, dependency** | coding-rules.md | Respect Module Boundaries | 294-318 |
| **defensive, check, validate** | coding-rules.md | Add Defensive Checks | 357-371 |
| **deterministic, side effect** | coding-rules.md | Prefer Deterministic Behavior | 372-392 |
| **magic, number, constant** | clean-code.md | Magic Numbers | 31-60 |
| **string, hardcoded, text** | clean-code.md | Hardcoded Strings | 61-89 |
| **guard, early, return** | clean-code.md | Return Early (Guard Clauses) | 90-123 |
| **guard, early, return, blank, spacing** | code-style.md | Guard Clause Spacing | 127-155 |
| **nesting, nested, if** | clean-code.md | Avoid Deep Nesting | 124-154 |
| **naming, name, variable** | clean-code.md | Meaningful Names | 155-199 |
| **single, responsibility, split** | clean-code.md | Single Responsibility | 200-230 |
| **dry, repeat, duplicate** | clean-code.md | DRY | 231-258 |
| **function, method, size** | clean-code.md | Function Size | 259-293 |
| **parameter, argument, limit** | clean-code.md | Parameter Limit | 294-327 |
| **class, god, large** | clean-code.md | Avoid God Classes | 328-358 |
| **immutable, mutable, let, final** | clean-code.md | Prefer Immutability | 359-389 |
| **error, exception, handling** | clean-code.md | Explicit Error Handling | 390-419 |
| **composition, inheritance** | clean-code.md | Prefer Composition Over Inheritance | 420-448 |
| **optimization, premature, performance** | clean-code.md | Avoid Premature Optimization | 477-498 |
| **file, size, length** | clean-code.md | File Size Limits | 499-516 |
| **condition, named, boolean** | clean-code.md | Named Condition Variables | 536-569 |
| **indent, space, format** | code-style.md | Indentation | 32-61 |
| **line, length, wrap** | code-style.md | Line Length | 62-75 |
| **statement, one, per line** | code-style.md | One Statement Per Line | 76-97 |
| **blank, line, separate, step** | code-style.md | Blank Lines Between Logical Steps | 98-126 |
| **blank, return, block** | code-style.md | Blank Line Before Return Blocks | 156-182 |
| **dense, compact, one-liner** | code-style.md | Avoid Dense Code | 183-204 |
| **condition, if, format** | code-style.md | Condition Formatting | 205-231 |
| **function, format, signature** | code-style.md | Function Formatting | 232-257 |
| **parameter, format, multiline** | code-style.md | Parameter Formatting | 258-281 |
| **chain, chained, call** | code-style.md | Chained Calls Formatting | 282-305 |
| **comment, comments, doc** | code-style.md | Comments Style (see Precedence below) | 306-336 |
| **brace, braces** | code-style.md | Consistent Braces | 390-414 |
| **refactor, extract, method** | refactoring.md | When to Refactor | 3-5 |
| **reusable, extract, formatter** | refactoring.md | Reusable Logic — When to Extract | 6-34 |
| **flutter, widget, state, const, constructor** | flutter/flutter.md | Widgets | 5-8 |
| **auth, authorization, ownership, idor, access control** | security-authz.md | Broken Object-Level Authorization (IDOR) | 3-31 |

---

## Precedence
- The user's global `~/.claude/CLAUDE.md` wins over these rules when they conflict.
- Comments: CLAUDE.md is stricter than `code-style.md` Comments Style — no new comment without the user's approval, even for complex logic or business rules.

---

## Quick Reference by Category

### Structure & Architecture
- Clean Architecture layers → `core.md:3-9`
- Single Responsibility → `clean-code.md:200-230`
- DRY → `clean-code.md:231-258`

### Functions & Methods
- Size limits (20-30 lines) → `coding-rules.md:68-101`, `clean-code.md:259-293`
- Guard clauses / return early → `clean-code.md:90-123`
- Avoid deep nesting → `clean-code.md:124-154`, `coding-rules.md:102-132`

### Naming & Constants
- Magic numbers → `clean-code.md:31-60`
- Meaningful names → `clean-code.md:155-199`
- Hardcoded strings → `clean-code.md:61-89`

### Formatting
- Indentation → `code-style.md:32-61`
- Line length → `code-style.md:62-75`
- Blank lines between steps → `code-style.md:98-126`
- Guard clause spacing → `code-style.md:127-155`
- Blank line before return blocks → `code-style.md:156-182`

### Flutter Specific
- Const constructors, widget rules → `flutter/flutter.md:5-8`
- Extract formatters/constants → `flutter/flutter.md:9-88`

### AI Code Generation
- Follow existing patterns → `coding-rules.md:25-39`
- Prefer predictable patterns → `coding-rules.md:40-67`
- Clarity over cleverness → `coding-rules.md:10-24`

### Refactoring
- When to refactor → `refactoring.md:3-5`
- Extract shared logic → `refactoring.md:6-75`

### Security — Authorization
- Object-level authorization / IDOR / ownership checks (any language/framework) → `security-authz.md` (always load for review, not keyword-gated)

---

## File Statistics
- `core.md`: 15 lines (always loaded, ngôn ngữ-agnostic)
- `general/clean-code.md`: ~610 lines
- `general/code-style.md`: ~465 lines
- `general/coding-rules.md`: ~440 lines
- `general/refactoring.md`: ~75 lines
- `general/security-authz.md`: ~60 lines
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

> **Note:** `general/` chứa rule ngôn ngữ-agnostic (áp dụng mọi ngôn ngữ). `flutter/` chứa rule riêng cho Flutter/Dart, chỉ load khi project hiện tại dùng Flutter. Thêm folder tương tự (vd: `rails/`, `swift/`) khi cần rule riêng cho ngôn ngữ/framework khác. Hiện chưa có folder cho Swift/iOS.
