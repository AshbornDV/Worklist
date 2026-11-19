import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/models/notification_model.dart';
import '../../core/notifications/models/notification_settings.dart';
import '../../core/notifications/repositories/notification_settings_repository.dart';

/// Notification settings screen. Lets the user enable/disable each category,
/// toggle the daily/weekly/monthly briefings, and customize sound, vibration,
/// priority, quiet hours and the briefing/report times.
///
/// It is a pure view/controller over [NotificationSettingsRepository] — it never
/// touches business data, rules, the engine, or delivery. Changes are persisted
/// immediately; the engine reads the same repository on its next refresh.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationSettingsRepository _repo;
  late NotificationSettings _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = context.read<NotificationSettingsRepository>();
    _settings = _repo.load();
    _loading = false;
  }

  Future<void> _save(NotificationSettings next) async {
    _settings = next;
    await _repo.save(next);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionTitle('Master'),
          SwitchListTile(
            title: const Text('Enable notifications'),
            value: s.masterEnabled,
            onChanged: (v) => _save(s.copyWith(masterEnabled: v)),
          ),
          const Divider(),
          const _SectionTitle('Categories'),
          _CategoryToggle('Payments', s.payments,
              (v) => _save(s.copyWith(payments: v))),
          _CategoryToggle('Payroll', s.payroll,
              (v) => _save(s.copyWith(payroll: v))),
          _CategoryToggle('Inventory', s.inventory,
              (v) => _save(s.copyWith(inventory: v))),
          _CategoryToggle('Workers', s.workers,
              (v) => _save(s.copyWith(workers: v))),
          _CategoryToggle('Attendance', s.attendance,
              (v) => _save(s.copyWith(attendance: v))),
          _CategoryToggle('Sites', s.sites,
              (v) => _save(s.copyWith(sites: v))),
          _CategoryToggle('Services', s.services,
              (v) => _save(s.copyWith(services: v))),
          const Divider(),
          const _SectionTitle('Smart Summaries'),
          _CategoryToggle('Daily Summary (Morning Briefing)', s.dailySummary,
              (v) => _save(s.copyWith(dailySummary: v))),
          if (s.dailySummary)
            _TimeTile(
              label: 'Daily briefing time',
              value: s.dailyBriefingTime,
              onPicked: (t) => _save(s.copyWith(dailyBriefingTime: t)),
            ),
          _CategoryToggle('Weekly Summary', s.weeklySummary,
              (v) => _save(s.copyWith(weeklySummary: v))),
          if (s.weeklySummary) ...[
            _TimeTile(
              label: 'Weekly report time',
              value: s.weeklyReportTime,
              onPicked: (t) => _save(s.copyWith(weeklyReportTime: t)),
            ),
            _WeekdayTile(
              value: s.weeklyReportWeekday,
              onPicked: (d) => _save(s.copyWith(weeklyReportWeekday: d)),
            ),
          ],
          _CategoryToggle('Monthly Summary', s.monthlySummary,
              (v) => _save(s.copyWith(monthlySummary: v))),
          if (s.monthlySummary) ...[
            _TimeTile(
              label: 'Monthly report time',
              value: s.monthlyReportTime,
              onPicked: (t) => _save(s.copyWith(monthlyReportTime: t)),
            ),
            _MonthDayTile(
              value: s.monthlyReportDay,
              onPicked: (d) => _save(s.copyWith(monthlyReportDay: d)),
            ),
          ],
          const Divider(),
          const _SectionTitle('Customization'),
          SwitchListTile(
            title: const Text('Sound'),
            value: s.sound,
            onChanged: (v) => _save(s.copyWith(sound: v)),
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            value: s.vibration,
            onChanged: (v) => _save(s.copyWith(vibration: v)),
          ),
          ListTile(
            title: const Text('Default priority'),
            trailing: DropdownButton<NotificationPriority>(
              value: s.priority,
              items: NotificationPriority.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (p) => _save(s.copyWith(priority: p!)),
            ),
          ),
          SwitchListTile(
            title: const Text('Quiet hours'),
            subtitle: Text(
              s.quietHoursEnabled
                  ? '${_fmt(s.quietHoursStart)} – ${_fmt(s.quietHoursEnd)}'
                  : 'Silence non-critical at night',
            ),
            value: s.quietHoursEnabled,
            onChanged: (v) => _save(s.copyWith(quietHoursEnabled: v)),
          ),
          if (s.quietHoursEnabled) ...[
            _TimeTile(
              label: 'Quiet hours start',
              value: s.quietHoursStart,
              onPicked: (t) => _save(s.copyWith(quietHoursStart: t)),
            ),
            _TimeTile(
              label: 'Quiet hours end',
              value: s.quietHoursEnd,
              onPicked: (t) => _save(s.copyWith(quietHoursEnd: t)),
            ),
          ],
          _TimeTile(
            label: 'Default reminder time',
            value: s.reminderTimes.first,
            onPicked: (t) => _save(s.copyWith(reminderTimes: [t])),
          ),
        ],
      ),
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}

class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onPicked,
  });
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onPicked;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label),
        trailing: TextButton(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value,
            );
            if (picked != null) onPicked(picked);
          },
          child: Text(
            '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
          ),
        ),
      );
}

class _WeekdayTile extends StatelessWidget {
  const _WeekdayTile({required this.value, required this.onPicked});
  final int value;
  final ValueChanged<int> onPicked;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('Weekly report day'),
        trailing: DropdownButton<int>(
          value: value,
          items: List.generate(7, (i) => i + 1)
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(_days[d - 1]),
                  ))
              .toList(),
          onChanged: (d) => onPicked(d!),
        ),
      );
}

class _MonthDayTile extends StatelessWidget {
  const _MonthDayTile({required this.value, required this.onPicked});
  final int value;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('Monthly report day'),
        trailing: DropdownButton<int>(
          value: value,
          items: List.generate(28, (i) => i + 1)
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text('Day $d'),
                  ))
              .toList(),
          onChanged: (d) => onPicked(d!),
        ),
      );
}

/// Wires the settings screen with its repository. The repository is a
/// lightweight SharedPreferences store, created lazily here so the screen is
/// self-contained (no app-level provider needed).
class NotificationSettingsScreenWithProvider extends StatelessWidget {
  const NotificationSettingsScreenWithProvider({super.key});

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<NotificationSettingsRepository>(
        future: NotificationSettingsRepository.create(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Provider<NotificationSettingsRepository>.value(
            value: snapshot.data!,
            child: const NotificationSettingsScreen(),
          );
        },
      );
}
