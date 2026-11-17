import 'package:material_ui/material_ui.dart';

class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF1565C0); // Deep Blue
  static const _secondary = Color(0xFF00897B); // Teal

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          secondary: _secondary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          labelType: NavigationRailLabelType.all,
          useIndicator: true,
        ),
        dividerTheme: const DividerThemeData(space: 1, thickness: 1),
        dialogTheme: const DialogThemeData(
          // Cap dialog width on tablets/desktop so forms and lists don't
          // stretch edge-to-edge; phones are unaffected (already < 560dp).
          constraints: BoxConstraints(maxWidth: 560),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          secondary: _secondary,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          labelType: NavigationRailLabelType.all,
          useIndicator: true,
        ),
        dividerTheme: const DividerThemeData(space: 1, thickness: 1),
        dialogTheme: const DialogThemeData(
          // Cap dialog width on tablets/desktop so forms and lists don't
          // stretch edge-to-edge; phones are unaffected (already < 560dp).
          constraints: BoxConstraints(maxWidth: 560),
        ),
      );

  // ── Status color helpers ──
  static Color statusColor(String status, ColorScheme cs) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF2E7D32);
      case 'completed':
        return cs.primary;
      case 'pending':
        return const Color(0xFFF57C00);
      case 'on_hold':
        return const Color(0xFF6D4C41);
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return cs.error;
      case 'inactive':
        return cs.outline;
      default:
        return cs.outline;
    }
  }

  static Color attendanceColor(String type, ColorScheme cs) {
    switch (type) {
      case 'full':
        return const Color(0xFF2E7D32);
      case 'half':
        return const Color(0xFFF57C00);
      case 'absent':
        return cs.error;
      default:
        return cs.outline;
    }
  }
}
