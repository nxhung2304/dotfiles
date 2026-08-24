# Flutter/Dart Specific Rules

Chỉ load khi project hiện tại là Flutter/Dart.

## Widgets
- Luôn dùng `const` constructors cho widgets khi có thể.
- Không magic numbers → dùng `AppSpacing`, `AppRadius`, `AppColors`...

## Refactoring — Extract Formatters/Constants
Nếu một formatter, regex, hoặc constant được dùng ở **2+ widgets/file**, extract ra file dùng chung.

**Structure:**
- Input formatters → `lib/core/formatters/input_formatters.dart`
- Number/date formatters → Extension trên type đó (vd: `double_extension.dart`)
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

Format methods biến đổi **type A → type B** nên là extension hoặc utility function:

```dart
_totalHours.toHoursDisplay(suffix: TimesheetStrings.formHoursSuffix)
```

### File Organization Checklist
- [ ] Formatter/helper dùng 2+ lần? → Extract vào `core/formatters/` hoặc `core/extensions/`
- [ ] Constants bị duplicate? → Move vào `core/constants/`
- [ ] Extension method? → Đặt tại `core/extensions/[type]_extension.dart`
- [ ] Import đã update? → Add import ở file dùng code đã extract
- [ ] Documentation? → Add doc comment cho public methods/constants

### Example: Before → After

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
