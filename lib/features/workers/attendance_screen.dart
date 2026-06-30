import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/attendance_model.dart';
import '../../core/providers/site_provider.dart';
import '../../core/providers/worker_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _date = DateTime.now();
  int? _siteId;
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  String get _dateKey =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    final siteProvider = context.read<SiteProvider>();
    if (siteProvider.sites.isEmpty) {
      await siteProvider.loadSites();
    }
    if (!mounted) return;
    final sites = siteProvider.sites;
    setState(() {
      _siteId = sites.isEmpty ? null : sites.first.id;
    });
    await _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (_siteId == null) {
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final rows = await context
        .read<WorkerProvider>()
        .getSiteAttendanceForDate(_siteId!, _dateKey);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _loadAttendance();
  }

  Future<void> _setAttendance(Map<String, dynamic> row, String type) async {
    final ok = await context.read<WorkerProvider>().recordAttendance(
          AttendanceModel(
            workerId: row['id'] as int,
            siteId: _siteId!,
            date: _dateKey,
            type: type,
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    if (ok) {
      setState(() {
        row['attendance_type'] = type;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Failed to record attendance'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sites = context.watch<SiteProvider>().sites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Select date',
          ),
          IconButton(
            onPressed: _loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _siteId,
                    decoration: const InputDecoration(
                      labelText: 'Site',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: sites
                        .map((site) => DropdownMenuItem(
                              value: site.id,
                              child: Text(site.name),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() => _siteId = value);
                      await _loadAttendance();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_siteId == null) {
      return const EmptyState(
        icon: Icons.location_off_outlined,
        title: 'No sites available',
        subtitle: 'Create a site before recording attendance.',
      );
    }

    if (_rows.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No workers assigned',
        subtitle: 'Assign workers to this site to record attendance.',
      );
    }

    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final type =
            row['attendance_type'] as String? ?? AppConstants.attendanceAbsent;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  child: Text((row['name'] as String).substring(0, 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row['name'] as String,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(row['trade'] as String? ?? ''),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AttendanceBadge(type: type),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: AppConstants.attendanceFull,
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment(
                      value: AppConstants.attendanceHalf,
                      icon: Icon(Icons.timelapse_outlined),
                    ),
                    ButtonSegment(
                      value: AppConstants.attendanceAbsent,
                      icon: Icon(Icons.cancel_outlined),
                    ),
                  ],
                  selected: {type},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      _setAttendance(row, value.first),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
