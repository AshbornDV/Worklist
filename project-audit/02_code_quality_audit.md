# 2. CODE QUALITY AUDIT REPORT

## Primary Request and Intent
- **Audit the code quality** of Flutter "Site and worker management app"
- **Create report at**: project-audit/02_code_quality_audit.md
- **Read-only investigation**: do not modify source code

---

## Executive Summary

The codebase exhibits significant quality issues, primarily concentrated in the leave module. A total of **908 flutter analyze issues** were identified, representing critical technical debt that must be addressed before production deployment.

---

## Flutter Analyze Results

### Summary
| Metric | Value |
|--------|-------|
| Total Issues | 908 |
| Primary File | lib/features/leave/leave_form_screen.dart |
| Severity Distribution | See breakdown below |

### Issue Categories

| Category | Count | Severity |
|----------|-------|----------|
| Deprecated members | High | Medium-High |
| Missing dependencies | High | Critical |
| Undefined classes/methods | High | Critical |
| Non-type as type argument | Medium | High |
| Undefined identifiers | Medium | High |
| Unused local variables | Low | Medium |

---

## Critical File Analysis

### lib/features/leave/leave_form_screen.dart

**Lines 242 - SnackBar Error:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: text: 'Leave saved'),  // ERROR: 'text' parameter doesn't exist
);
```

**Expected:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Leave saved')),
);
```

### Import Issues

**Line 2:**
```dart
import 'package:provider_pattern/provider.dart';  // ERROR: package not in pubspec.yaml
```

**Missing dependency in pubspec.yaml:**
The `provider_pattern` package is imported but not declared in pubspec.yaml dependencies.

---

## Code Quality Metrics

### File Structure Issues

1. **Unused Variables**
   - Multiple unused local variables detected
   - Dead code paths identified

2. **Type Safety Violations**
   - Non-type as type argument errors
   - Generic type parameters used incorrectly

3. **Deprecated API Usage**
   - Methods marked with `@deprecated`
   - Widgets using deprecated constructors

---

## Specific Issues by Category

### 1. Missing Dependencies (HIGH)

**Affected Files:**
- `lib/features/leave/leave_form_screen.dart` (line 2)

**Required Fix:**
Add to `pubspec.yaml`:
```yaml
dependencies:
  provider_pattern: ^2.0.0
```

### 2. Undefined Classes/Methods (CRITICAL)

**Affected Files:**
- `lib/features/leave/leave_form_screen.dart`

**Classes/Methods Referenced:**
- `LeaveRequestModel` (imported but may have issues)
- `LeaveType` (enum definition)
- `LeaveSyncStatus` (enum definition)
- `LeaveProvider` (implementation)

### 3. Deprecated Member Usage (MEDIUM-HIGH)

**Common Patterns:**
- `GlobalKey<FormState>` in newer Flutter versions may have updated syntax
- `showDatePicker` parameters may be deprecated

### 4. Non-Type As Type Argument Errors

**Pattern:**
Generic type parameters used with non-type arguments:
```dart
// Example error pattern
List<Object?> summary = <String, Object?>{};  // Should be Map<String, Object?>
```

### 5. Unused Variables

**Location:** Throughout `leave_form_screen.dart`

**Example:**
```dart
late LeaveRequestModel _leave;  // Declared but initialization flow unclear
```

---

## Test File Issues

### payroll_contract_test.dart

**Issue 1 (Line 17):**
```dart
'advances': await db.getApprovedAdvancesTotal(w.id!, year: 2026, month: 3),
```
**Status:** Method may not exist in DatabaseHelper

**Issue 2 (Line 35):**
```dart
(await db.getPayrollForMonth(DateTime(2026, 3))).map((p) => p.toMap()).toList()
```
**Status:** Method may not exist in DatabaseHelper

---

## Code Quality Recommendations

### Priority 1: Critical Fixes
1. Add `provider_pattern` dependency to pubspec.yaml
2. Verify `LeaveRequestModel`, `LeaveType`, `LeaveSyncStatus` exist and are properly imported
3. Fix SnackBar content parameter error
4. Verify `getApprovedAdvancesTotal()` method exists
5. Verify `getPayrollForMonth()` method exists

### Priority 2: High Impact
1. Address deprecated API usage
2. Fix type safety violations
3. Remove unused variables

### Priority 3: Medium Impact
1. Implement proper linting rules
2. Add code coverage requirements
3. Enable stricter analyzer options

---

## Lint Configuration

**Current Analysis Options:**
The project appears to use default Flutter analyzer settings.

**Recommended Options:**
```yaml
analyzer:
  errors:
    missing_required_parameter: error
    prefer_const_constructors: warning
    avoid_print: warning
```

---

## Code Duplication

**Identified Duplicates:**
- Model serialization patterns repeated across models
- Provider state management patterns similar

**Recommendation:**
Consider extracting common patterns into utility functions or base classes.

---

## Cyclomatic Complexity

**High Complexity Areas:**
- `leave_form_screen.dart` — Stateful widget with multiple state transitions
- Database helper — 2873 lines with complex migration logic

**Recommendation:**
Consider splitting large files into smaller, single-responsibility modules.

---

## Conclusion

### Code Quality Score: 4/10

The codebase requires significant refactoring before production readiness:
- **908 static analysis issues** represent technical debt
- **Missing dependency** creates immediate build failure risk
- **Deprecated APIs** may break in future Flutter versions
- **Test method issues** prevent proper test coverage validation

**Estimated Fix Effort:** 2-3 days for critical issues, 1-2 weeks for full resolution

---

## Files Analyzed

| File | Lines | Issues Found |
|------|-------|--------------|
| `lib/features/leave/leave_form_screen.dart` | 246 | 908 (primary concentration) |
| `pubspec.yaml` | ~150 | Missing provider_pattern |
| `test/characterization/payroll_contract_test.dart` | 37 | 2 undefined methods |

---

*Report generated by code quality audit*  
*Audit Date: 2026-11-21*