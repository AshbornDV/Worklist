import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

/// Pull-to-refresh helper: downloads the latest data from Firebase FIRST,
/// then runs the screen's local [reloadLocal] (which re-reads SQLite). This
/// makes every RefreshIndicator follow: pull cloud → update SQLite → reload
/// providers → refresh UI, instead of only re-reading local SQLite. The
/// cloud pull is a no-op when the user isn't signed in to Firebase.
Future<void> syncThenReload(
  BuildContext context,
  Future<void> Function() reloadLocal,
) async {
  try {
    await context.read<AuthProvider>().pullFromCloudForRefresh();
  } catch (_) {
    // Never let a cloud hiccup block the local reload / refresh gesture.
  }
  await reloadLocal();
}

// ─────────────── STAT CARD ───────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? bgColor;
  final VoidCallback? onTap;
  final String? trend;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.bgColor,
    this.onTap,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = bgColor ?? cs.primaryContainer;
    final ic = iconColor ?? cs.primary;

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
                height: 1.2,
              ),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
        if (trend != null) ...[
          const SizedBox(height: 3),
          Text(
            trend!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep the horizontal icon+text row at every width; just shrink
              // the icon and its padding when the tile is narrow. The previous
              // "stack vertically below 170px" rule made the card taller
              // exactly when vertical space was scarcest, which overflowed
              // every dashboard stat card.
              final tight = constraints.maxWidth < 150;
              final box = Container(
                padding: EdgeInsets.all(tight ? 8 : 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(tight ? 10 : 14),
                ),
                child: Icon(icon, color: ic, size: tight ? 20 : 24),
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  box,
                  SizedBox(width: tight ? 8 : 14),
                  Expanded(child: texts),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────── SECTION HEADER ───────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────── INFO ROW ───────────────

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final TextStyle? valueStyle;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Scale the label column down a little on small phones so the value
    // (which can be arbitrarily long, e.g. notes or addresses) keeps as
    // much room as possible instead of being squeezed by a fixed width.
    final labelWidth = MediaQuery.sizeOf(context).width < 360 ? 96.0 : 120.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── STATUS BADGE ───────────────

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = AppTheme.statusColor(status, cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────── ATTENDANCE BADGE ───────────────

class AttendanceBadge extends StatelessWidget {
  final String type;

  const AttendanceBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = AppTheme.attendanceColor(type, cs);
    final label = type == 'full'
        ? 'Full Day'
        : type == 'half'
            ? 'Half Day'
            : 'Absent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────── EMPTY STATE ───────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: compact ? 56 : 72,
                color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              // Keep the call to action a normal button size. Without a cap it
              // stretches to the full panel width on wide screens.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SizedBox(width: double.infinity, child: action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────── CURRENCY DISPLAY ───────────────

class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool compact;

  const CurrencyText(this.amount,
      {super.key, this.style, this.compact = false});

  static String format(double amount, {bool compact = false}) {
    final formatted = compact ? _compact(amount) : _full(amount);
    return 'Rs. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final formatted = compact ? _compact(amount) : _full(amount);
    return Text('Rs. $formatted', style: style);
  }

  static String _full(double v) {
    final abs = v.abs();
    final str = abs.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(str[i]);
      count++;
    }
    return (v < 0 ? '-' : '') + buf.toString().split('').reversed.join('');
  }

  static String _compact(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    if (abs >= 1000000) return '$prefix${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(1)}K';
    return '$prefix${abs.toStringAsFixed(0)}';
  }
}

// ─────────────── CONFIRM DIALOG ───────────────

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
