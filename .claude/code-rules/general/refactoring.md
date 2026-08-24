# Refactoring & Code Organization

## When to Refactor
Khi logic/formatter/constant xuất hiện ở **2+ nơi**, hoặc file/function vượt quá size limit (xem `clean-code.md`), cân nhắc extract/refactor.

## Reusable Logic — When to Extract

### Rule 1: Repeated Formatters/Constants
Nếu một formatter, regex, hoặc constant được dùng ở **2+ nơi**, extract ra module dùng chung.

```
# ❌ Sai — Duplicated regex in multiple files
# file_a
validate(value, pattern="^\d*[.,]?\d*")

# file_b (future)
validate(value, pattern="^\d*[.,]?\d*")

# ✅ Đúng — Extract to shared constant
# core/formatters.*
DECIMAL_HOURS_PATTERN = "^\d*[.,]?\d*"

# Usage in any file:
validate(value, pattern=DECIMAL_HOURS_PATTERN)
```

### Rule 2: Display/Format Methods
Method biến đổi **type A → type B** nên là utility function hoặc extension/helper method của type đó, không lặp lại logic format ở từng call site.

```
# Usage:
totalHours.toDisplayString(suffix=HOURS_SUFFIX)
```

## File Organization Checklist

Khi extract hoặc tạo file mới:

- [ ] **Helper dùng 2+ lần?** → Extract vào `core/formatters` hoặc `core/utils`
- [ ] **Constants bị duplicate?** → Move vào `core/constants` hoặc file constants riêng
- [ ] **Import đã update?** → Add import ở file dùng code đã extract
- [ ] **Documentation added?** → Thêm doc comment cho public methods/constants

## Example: Good Refactoring

**Before:**
```
# form_screen.*
function displayTotalHours() {
  total = entries.reduce(sum by hours)
  return format(total, suffix=HOURS_SUFFIX)
}

# entry_block.*
validate(value, pattern="^\d*\.?\d*")
```

**After:**
```
# core/formatters.*
DECIMAL_HOURS_PATTERN = "^\d*[.,]?\d*"

# core/extensions.*
function toDisplayString(value, suffix=HOURS_SUFFIX) {
  return format(value, suffix)
}

# form_screen.*
function buildTotalBar() {
  return render(totalHours.toDisplayString())
}

# entry_block.*
validate(value, pattern=DECIMAL_HOURS_PATTERN)
```
