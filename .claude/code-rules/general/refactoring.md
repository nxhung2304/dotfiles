# Refactoring & Code Organization

## Reusable Logic — When to Extract

### Rule 1: Input Formatters & Constants
If a formatter, regex, or constant is used in **2+ locations or widgets**, extract to a dedicated file.

**Structure:**
- Input formatters → `lib/core/formatters/input_formatters.dart`
- Number/date formatters → Extension on the type (e.g., `double_extension.dart`)
- Generic constants → `lib/core/constants/`

```dart
// ❌ Sai — Duplicated regex in multiple files
// timesheet_entry_block.dart
inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*'))]

// ot_screen.dart (future)
inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*'))]

// ✅ Đúng — Extract to constants
// lib/core/formatters/input_formatters.dart
class InputFormatters {
  static final decimalHours = FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*'));
}

// Usage in any file:
inputFormatters: [InputFormatters.decimalHours]
```

### Rule 2: Display/Format Methods
Format methods that transform **one type → another** should be extensions or utility functions.

```dart
// Usage:
_totalHours.toHoursDisplay(suffix: TimesheetStrings.formHoursSuffix)
```

## File Organization Checklist

When extracting or creating new files:

- [ ] **Formatter/helper used 2+ times?** → Extract to `core/formatters/` or `core/extensions/`
- [ ] **Constants duplicated?** → Move to `core/constants/` or dedicated constants file
- [ ] **Extension method?** → Place in `core/extensions/[type]_extension.dart`
- [ ] **Import updated?** → Add import in file that uses the extracted code
- [ ] **Documentation added?** → Add doc comments for public methods/constants

## Example: Good Refactoring

**Before:**
```dart
// timesheet_form_screen.dart
String displayTotalHours() {
  final total = _entries.fold(0.0, (sum, entry) => sum + entry.hours);
  return "${total.toStringAsFixed(1)} ${TimesheetStrings.formHoursSuffix}";
}

// timesheet_entry_block.dart
inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
]
```

**After:**
```dart
// lib/core/formatters/input_formatters.dart
class InputFormatters {
  /// Accepts decimal hours input (0-9, . or , separator)
  static final decimalHours = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*[.,]?\d*'),
  );
}

// lib/core/extensions/double_extension.dart
extension DoubleFormatting on double {
  String toHoursDisplay({String suffix = AppStrings.hoursSuffix}) {
    return '${toStringAsFixed(1)} $suffix';
  }
}

// timesheet_form_screen.dart
Widget _buildTotalBar() {
  return Text(_totalHours.toHoursDisplay());
}

// timesheet_entry_block.dart
inputFormatters: [InputFormatters.decimalHours]
```
