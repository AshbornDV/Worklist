import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/advance_payment_model.dart';
import '../../core/models/site_model.dart';
import '../../core/models/worker_model.dart';
import '../../core/providers/worker_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';

class WorkerDetailScreen extends StatefulWidget {
  final int workerId;
  const WorkerDetailScreen({required this.workerId, super.key});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen>
    with SingleTickerProviderStateMixin {
  WorkerModel? _worker;
  WorkerPaycheck? _paycheck;
  bool _loading = true;
  late DateTime _selectedMonth;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prov = context.read<WorkerProvider>();
    final worker = await prov.getWorker(widget.workerId);
    if (worker != null && mounted) {
      final paycheck = await prov.calculatePaycheck(
          worker, _selectedMonth.year, _selectedMonth.month);
      await prov.loadAttendance(worker.id!,
          year: _selectedMonth.year, month: _selectedMonth.month);
      await prov.loadAdvances(worker.id!);
      if (mounted) {
        setState(() {
          _worker = worker;
          _paycheck = paycheck;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    await _load();
  }

  Future<void> _deleteWorker() async {
    final worker = _worker;
    if (worker == null) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Worker',
      content:
          'Delete "${worker.name}"? All attendance and advance records will be removed.',
      confirmText: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<WorkerProvider>().deleteWorker(worker.id!);
    if (mounted) context.go('/workers');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Worker Not Found')),
        body: const EmptyState(
          icon: Icons.person_off,
          title: 'Worker not found',
        ),
      );
    }

    final worker = _worker!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(worker.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black38)])),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white24,
                      child: Text(
                        worker.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(worker.trade,
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.white24,
                      labelStyle: const TextStyle(color: Colors.white),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => context.go('/workers/${worker.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteWorker,
              ),
              const SizedBox(width: 4),
            ],
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Paycheck', icon: Icon(Icons.receipt_long, size: 18)),
                Tab(
                    text: 'Attendance',
                    icon: Icon(Icons.calendar_month, size: 18)),
                Tab(text: 'Advances', icon: Icon(Icons.payments, size: 18)),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _PaycheckTab(
              worker: worker,
              paycheck: _paycheck,
              selectedMonth: _selectedMonth,
              onPrevMonth: () => _changeMonth(-1),
              onNextMonth: () => _changeMonth(1),
            ),
            _AttendanceTab(worker: worker),
            _AdvancesTab(worker: worker, onRefresh: _load),
          ],
        ),
      ),
    );
  }
}

// ─────────────── PAYCHECK TAB ───────────────

class _PaycheckTab extends StatelessWidget {
  final WorkerModel worker;
  final WorkerPaycheck? paycheck;
  final DateTime selectedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _PaycheckTab({
    required this.worker,
    required this.paycheck,
    required this.selectedMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pc = paycheck;
    final monthName =
        '${_months[selectedMonth.month - 1]} ${selectedMonth.year}';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // ── Worker Info ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InfoRow(
                      label: 'Daily Rate',
                      value: 'Rs. ${worker.dailyRate.toStringAsFixed(0)}',
                      icon: Icons.attach_money),
                  InfoRow(
                      label: 'Half Day Rate',
                      value: 'Rs. ${worker.halfDayRate.toStringAsFixed(0)}',
                      icon: Icons.timelapse),
                  InfoRow(
                      label: 'Phone',
                      value: worker.phone.isEmpty ? '–' : worker.phone,
                      icon: Icons.phone_outlined),
                  InfoRow(
                      label: 'Status',
                      value: worker.status.toUpperCase(),
                      icon: Icons.circle,
                      valueStyle: TextStyle(
                          color: AppTheme.statusColor(worker.status, cs),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Month selector ──
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: onPrevMonth,
                      icon: const Icon(Icons.chevron_left)),
                  Expanded(
                    child: Text(
                      monthName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: selectedMonth.month == DateTime.now().month &&
                            selectedMonth.year == DateTime.now().year
                        ? null
                        : onNextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Paycheck breakdown ──
          if (pc != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Paycheck Summary',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    _PCRow('Full Days Worked', '${pc.fullDays} days', null),
                    _PCRow('Half Days Worked', '${pc.halfDays} days', null),
                    _PCRow('Gross Earnings', null, pc.grossEarnings,
                        color: cs.primary),
                    _PCRow('Advances Deducted', null, pc.totalAdvances,
                        negative: true, color: const Color(0xFFF57C00)),
                    const Divider(height: 24),
                    _PCRow(
                      pc.hasDebt ? 'Debt (next month)' : 'Net Payable',
                      null,
                      pc.netPayable.abs(),
                      color: pc.hasDebt
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF2E7D32),
                      bold: true,
                      large: true,
                    ),
                    if (pc.hasDebt) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚠️  Advances exceed earnings for this month. Debt carries to next month.',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}

class _PCRow extends StatelessWidget {
  final String label;
  final String? strVal;
  final double? amount;
  final Color? color;
  final bool negative;
  final bool bold;
  final bool large;

  const _PCRow(this.label, this.strVal, this.amount,
      {this.color,
      this.negative = false,
      this.bold = false,
      this.large = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: large ? 15 : 14)),
          strVal != null
              ? Text(strVal!,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color ?? cs.onSurface))
              : Row(
                  children: [
                    if (negative)
                      Text('− ',
                          style: TextStyle(color: color ?? cs.onSurface)),
                    CurrencyText(
                      amount!,
                      style: TextStyle(
                          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                          color: color ?? cs.onSurface,
                          fontSize: large ? 18 : 14),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ─────────────── ATTENDANCE TAB ───────────────

class _AttendanceTab extends StatelessWidget {
  final WorkerModel worker;
  const _AttendanceTab({required this.worker});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<WorkerProvider>().attendanceRecords;
    final cs = Theme.of(context).colorScheme;

    if (records.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No attendance recorded',
        subtitle: 'Attendance records will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = records[i];
        final color = AppTheme.attendanceColor(r.type, cs);
        return Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                r.type == 'full'
                    ? Icons.wb_sunny_rounded
                    : r.type == 'half'
                        ? Icons.wb_cloudy_rounded
                        : Icons.close_rounded,
                color: color,
                size: 20,
              ),
            ),
            title: Text(_fmtDate(r.date),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: r.siteName != null ? Text(r.siteName!) : null,
            trailing: AttendanceBadge(type: r.type),
          ),
        );
      },
    );
  }

  String _fmtDate(String d) {
    final parts = d.split('-');
    if (parts.length < 3) return d;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = int.tryParse(parts[1]);
    return '${parts[2]} ${month != null ? months[month - 1] : parts[1]} ${parts[0]}';
  }
}

// ─────────────── ADVANCES TAB ───────────────

class _AdvancesTab extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onRefresh;

  const _AdvancesTab({required this.worker, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WorkerProvider>();
    final advances = prov.advances;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FilledButton.icon(
            onPressed: () => _showRequestDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Request Advance'),
          ),
        ),
        Expanded(
          child: advances.isEmpty
              ? const EmptyState(
                  icon: Icons.payments_outlined,
                  title: 'No advances',
                  subtitle: 'Advance requests will appear here',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: advances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AdvanceTile(
                    advance: advances[i],
                    onApprove: () async {
                      await prov.approveAdvance(advances[i].id!);
                      onRefresh();
                    },
                    onReject: () async {
                      await prov.rejectAdvance(advances[i].id!);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showRequestDialog(BuildContext context) async {
    final prov = context.read<WorkerProvider>();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Advance'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amtCtrl,
                decoration: const InputDecoration(
                    labelText: 'Amount (Rs.)',
                    prefixIcon: Icon(Icons.payments)),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  if ((double.tryParse(v) ?? 0) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    prefixIcon: Icon(Icons.notes)),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await prov.requestAdvance(AdvancePaymentModel(
                workerId: worker.id!,
                amount: double.parse(amtCtrl.text),
                requestDate: DateTime.now(),
                status: 'pending',
                notes:
                    noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                createdAt: DateTime.now(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
    amtCtrl.dispose();
    noteCtrl.dispose();
  }
}

class _AdvanceTile extends StatelessWidget {
  final AdvancePaymentModel advance;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdvanceTile(
      {required this.advance, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CurrencyText(
                    advance.amount,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                StatusBadge(status: advance.status),
              ],
            ),
            if (advance.notes != null) ...[
              const SizedBox(height: 4),
              Text(advance.notes!,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  'Requested: ${_fmt(advance.requestDate)}',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            if (advance.isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: cs.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ─────────────── WORKER SUMMARY PANEL (embeddable, no Scaffold) ───────────────

/// A compact embeddable worker profile for use in master-detail layouts on
/// wide desktop screens. Shows key info and a link to the full detail screen.
class WorkerSummaryPanel extends StatefulWidget {
  final int workerId;
  const WorkerSummaryPanel({required this.workerId, super.key});

  @override
  State<WorkerSummaryPanel> createState() => _WorkerSummaryPanelState();
}

class _WorkerSummaryPanelState extends State<WorkerSummaryPanel> {
  WorkerModel? _worker;
  List<SiteModel> _sites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WorkerSummaryPanel old) {
    super.didUpdateWidget(old);
    if (old.workerId != widget.workerId) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prov = context.read<WorkerProvider>();
    final worker = await prov.getWorker(widget.workerId);
    if (!mounted) return;
    if (worker != null) {
      final sites = await prov.getWorkerSites(worker.id!);
      if (!mounted) return;
      setState(() {
        _worker = worker;
        _sites = sites;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_worker == null) {
      return const EmptyState(
        icon: Icons.person_off,
        title: 'Worker not found',
        subtitle: 'This worker may have been deleted',
      );
    }

    final w = _worker!;
    final isActive = w.status == 'active';
    final avatarColor =
        isActive ? cs.primaryContainer : cs.surfaceContainerHighest;
    final avatarTextColor = isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.5);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarColor,
                      child: Text(
                        w.name[0].toUpperCase(),
                        style: TextStyle(
                          color: avatarTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            w.trade,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: w.status),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit worker',
                onPressed: () => context.go('/workers/${w.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                tooltip: 'Open full profile',
                onPressed: () => context.go('/workers/${w.id}'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Key info card ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Worker Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  InfoRow(
                    label: 'Daily Rate',
                    value: CurrencyText.format(w.dailyRate),
                    icon: Icons.attach_money_rounded,
                  ),
                  InfoRow(
                    label: 'Half Day Rate',
                    value: CurrencyText.format(w.halfDayRate),
                    icon: Icons.timelapse_outlined,
                  ),
                  InfoRow(
                    label: 'Phone',
                    value: w.phone.isEmpty ? '—' : w.phone,
                    icon: Icons.phone_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Assigned sites ──
          SectionHeader(
            title: 'Assigned Sites',
            subtitle: '${_sites.length} site(s)',
          ),
          if (_sites.isEmpty)
            const EmptyState(
              icon: Icons.location_off_outlined,
              title: 'Not assigned to any site',
              subtitle: 'Assign this worker to a site from the Sites screen',
            )
          else
            ..._sites.map(
              (s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.location_city_outlined,
                      color: cs.primary),
                  title: Text(s.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(s.area),
                  trailing: StatusBadge(status: s.status),
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () => context.go('/sites/${s.id}'),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── Open full profile button ──
          OutlinedButton.icon(
            onPressed: () => context.go('/workers/${w.id}'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View paycheck, attendance & advances'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}
