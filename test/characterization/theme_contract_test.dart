import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Color, ColorScheme;
import 'package:path/path.dart' as p;
import 'package:worklist/core/theme/app_theme.dart';

/// Freezes the Flutter theme into `contracts/theme.json`.
///
/// Unlike the other characterization contracts this does not use [expectGolden]
/// (that helper writes one file per name under `contracts/expectations/`). The
/// theme contract is a single object with `light`/`dark`/`status`/`attendance`/
/// `shape` keys, so this test writes and byte-compares the file directly.
void main() {
  test('theme contract matches the frozen Flutter theme', () {
    final light = AppTheme.lightTheme.colorScheme;
    final dark = AppTheme.darkTheme.colorScheme;

    final lightRoles = _schemeToJson(light);
    final darkRoles = _schemeToJson(dark);
    final status = _statusToJson(light);
    final attendance = _attendanceToJson(light);
    final shape = _shapeToJson();

    // Sanity checks on the in-memory contract so they hold in both modes.
    expect(lightRoles['primary'], isNotNull);
    expect(darkRoles['primary'], isNotNull);
    expect(lightRoles['primary'], isNot(darkRoles['primary']),
        reason: 'light/dark primary must be different tonal derivatives');
    expect(shape['cardRadius'], 14);

    final contract = <String, Object?>{
      'light': lightRoles,
      'dark': darkRoles,
      'status': status,
      'attendance': attendance,
      'shape': shape,
    };

    final encoded = const JsonEncoder.withIndent('  ').convert(contract);
    final file = File(
      p.join(Directory.current.path, 'contracts', 'theme.json'),
    );

    // This contract has its own writer - do not use expectGolden.
    if (const bool.fromEnvironment('UPDATE_GOLDENS')) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('$encoded\n');
      return;
    }

    expect(
      file.existsSync(),
      isTrue,
      reason: 'Missing contract ${file.path}. '
          'Regenerate it with --dart-define=UPDATE_GOLDENS=true.',
    );
    expect(
      encoded,
      file.readAsStringSync().trimRight(),
      reason: 'Theme contract drifted from the frozen Flutter behaviour.',
    );
  });
}

/// 34 ColorScheme roles the app reads. The `*Fixed` family is intentionally
/// skipped.
Map<String, String> _schemeToJson(ColorScheme cs) => {
      'primary': _hex(cs.primary),
      'onPrimary': _hex(cs.onPrimary),
      'primaryContainer': _hex(cs.primaryContainer),
      'onPrimaryContainer': _hex(cs.onPrimaryContainer),
      'secondary': _hex(cs.secondary),
      'onSecondary': _hex(cs.onSecondary),
      'secondaryContainer': _hex(cs.secondaryContainer),
      'onSecondaryContainer': _hex(cs.onSecondaryContainer),
      'tertiary': _hex(cs.tertiary),
      'onTertiary': _hex(cs.onTertiary),
      'tertiaryContainer': _hex(cs.tertiaryContainer),
      'onTertiaryContainer': _hex(cs.onTertiaryContainer),
      'error': _hex(cs.error),
      'onError': _hex(cs.onError),
      'errorContainer': _hex(cs.errorContainer),
      'onErrorContainer': _hex(cs.onErrorContainer),
      'surface': _hex(cs.surface),
      'onSurface': _hex(cs.onSurface),
      'surfaceDim': _hex(cs.surfaceDim),
      'surfaceBright': _hex(cs.surfaceBright),
      'surfaceContainerLowest': _hex(cs.surfaceContainerLowest),
      'surfaceContainerLow': _hex(cs.surfaceContainerLow),
      'surfaceContainer': _hex(cs.surfaceContainer),
      'surfaceContainerHigh': _hex(cs.surfaceContainerHigh),
      'surfaceContainerHighest': _hex(cs.surfaceContainerHighest),
      'onSurfaceVariant': _hex(cs.onSurfaceVariant),
      'outline': _hex(cs.outline),
      'outlineVariant': _hex(cs.outlineVariant),
      'shadow': _hex(cs.shadow),
      'scrim': _hex(cs.scrim),
      'inverseSurface': _hex(cs.inverseSurface),
      'onInverseSurface': _hex(cs.onInverseSurface),
      'inversePrimary': _hex(cs.inversePrimary),
      'surfaceTint': _hex(cs.surfaceTint),
    };

/// Every switch arm of [AppTheme.statusColor] plus `default`, resolved against
/// the light scheme. `default` is produced by an unrecognised value so it
/// captures the `cs.outline` fallback the Kotlin port must reproduce.
Map<String, String> _statusToJson(ColorScheme light) => {
      'active': _hex(AppTheme.statusColor('active', light)),
      'completed': _hex(AppTheme.statusColor('completed', light)),
      'pending': _hex(AppTheme.statusColor('pending', light)),
      'on_hold': _hex(AppTheme.statusColor('on_hold', light)),
      'approved': _hex(AppTheme.statusColor('approved', light)),
      'rejected': _hex(AppTheme.statusColor('rejected', light)),
      'inactive': _hex(AppTheme.statusColor('inactive', light)),
      'default': _hex(AppTheme.statusColor('unknown', light)),
    };

/// Every switch arm of [AppTheme.attendanceColor] plus `default`, resolved
/// against the light scheme.
Map<String, String> _attendanceToJson(ColorScheme light) => {
      'full': _hex(AppTheme.attendanceColor('full', light)),
      'half': _hex(AppTheme.attendanceColor('half', light)),
      'absent': _hex(AppTheme.attendanceColor('absent', light)),
      'default': _hex(AppTheme.attendanceColor('unknown', light)),
    };

/// Shape/theme numbers from `app_theme.dart`.
Map<String, int> _shapeToJson() => {
      'cardRadius': 14,
      'cardElevation': 1,
      'inputRadius': 12,
      'inputPaddingH': 16,
      'inputPaddingV': 14,
      'filledButtonMinHeight': 50,
      'buttonRadius': 12,
      'elevatedPaddingH': 24,
      'elevatedPaddingV': 12,
      'chipRadius': 8,
      'dividerSpace': 1,
      'dividerThickness': 1,
      'dialogMaxWidth': 560,
    };

/// ARGB hex string `#AARRGGBB`, padded and uppercased.
String _hex(Color color) {
  final argb = color.toARGB32().toUnsigned(32);
  return '#${argb.toRadixString(16).toUpperCase().padLeft(8, '0')}';
}
