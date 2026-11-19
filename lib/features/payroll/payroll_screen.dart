import 'package:material_ui/material_ui.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../../core/models/payroll_model.dart';
import '../../core/models/worker_model.dart';
import '../../core/providers/worker_provider.dart';
import '../../core/services/payslip_service.dart';
import '../../shared/widgets/shared_widgets.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  late DateTime _selectedMonth;
  List<WorkerModel> _workers = [];
  List<PayrollModel> _payrolls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prov = context.read<WorkerProvider>();
    try {
      if (prov.workers.isEmpty) {
        await prov.loadWorkers();
      }
      final workers = prov.workers;
      final payrolls = await prov.getPayrollForMonth(_selectedMonth);
      if (mounted) {
        setState(() {
          _workers = workers;
          _payrolls = payrolls;
          _loading = false;
        });
      }
    } catch (_) {
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

  PayrollModel? _payrollFor(WorkerModel worker) {
    for (final p in _payrolls) {
      if (p.workerId == worker.id) return p;
    }
    return null;
  }

  Future<void> _generateOrEdit(WorkerModel worker) async {
    final prov = context.read<WorkerProvider>();
    final existing = _payrollFor(worker);

    PayrollModel payroll;
    if (existing != null) {
      payroll = existing;
    } else {
      payroll = await prov.generatePayroll(
        worker,
        _selectedMonth.year,
        _selectedMonth.month,
      );
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _PayrollEditDialog(
        worker: worker,
        payroll: payroll,
        month: _selectedMonth,
      ),
    );

    if (result == true && mounted) {
      await _load();
    }
  }

  Future<void> _markPaid(PayrollModel payroll) async {
    final prov = context.read<WorkerProvider>();
    final ok = await prov.markPayrollPaid(payroll.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Marked as paid' : (prov.error ?? 'Failed')),
        backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
      ),
    );
    if (ok) await _load();
  }

  Future<void> _generatePayslip(
      WorkerModel worker, PayrollModel payroll) async {
    try {
      final file = await PayslipService.instance.generatePayslip(
        worker: worker,
        payroll: payroll,
      );
      if (!mounted) return;
      final result = await OpenFile.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payslip saved: ${file.path}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate payslip: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _delete(PayrollModel payroll) async {
    final prov = context.read<WorkerProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payroll'),
        content: const Text(
          'Delete this payroll record? You can regenerate it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await prov.deletePayroll(payroll.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Payroll deleted' : (prov.error ?? 'Failed')),
        backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
      ),
    );
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthName =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Payroll'),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No workers',
                  subtitle: 'Add workers first to generate payroll',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  // Single lazy scroller: header items (month selector, summary,
                  // section header) + one builder item per worker. Supports
                  // thousands of records with no eager building and no nested
                  // scroll views.
                  itemCount: 3 + _workers.length,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => _changeMonth(-1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text(
                                  monthName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _isCurrentMonth()
                                    ? null
                                    : () => _changeMonth(1),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (i == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _SummaryCard(payrolls: _payrolls),
                      );
                    }
                    if (i == 2) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: SectionHeader(
                          title: 'Workers',
                          subtitle:
                              'Generate or edit monthly salary per worker',
                        ),
                      );
                    }
                    final w = _workers[i - 3];
                    final p = _payrollFor(w);
                    return _WorkerPayrollTile(
                      worker: w,
                      payroll: p,
                      onGenerate: () => _generateOrEdit(w),
                      onMarkPaid: p == null ? null : () => _markPaid(p),
                      onDelete: p == null ? null : () => _delete(p),
                      onDownloadPayslip:
                          p == null ? null : () => _generatePayslip(w, p),
                    );
                  },
                ),
    );
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  static const _monthNames = [
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

class _SummaryCard extends StatelessWidget {
  final List<PayrollModel> payrolls;
  const _SummaryCard({required this.payrolls});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final generated = payrolls.length;
    final paid = payrolls.where((p) => p.isPaid).length;
    final totalGross = payrolls.fold(0.0, (sum, p) => sum + p.grossSalary);
    final totalNet = payrolls.fold(0.0, (sum, p) => sum + p.netSalary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _SummaryStat(
                label: 'Generated',
                value: '$generated',
                color: cs.primary,
              ),
            ),
            Expanded(
              child: _SummaryStat(
                label: 'Paid',
                value: '$paid',
                color: const Color(0xFF2E7D32),
              ),
            ),
            Expanded(
              child: _SummaryStat(
                label: 'Total Gross',
                value: CurrencyText.format(totalGross, compact: true),
                color: const Color(0xFF0288D1),
              ),
            ),
            Expanded(
              child: _SummaryStat(
                label: 'Total Net',
                value: CurrencyText.format(totalNet, compact: true),
                color: const Color(0xFFC2185B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Responsive worker payroll row.
///
/// Layout (constraint-correct, no magic widths forcing zero-width):
///  • worker info  → [Expanded(flex: 4)]
///  • payroll values → [Expanded(flex: 3)] (Gross / Advance / Net, right aligned)
///  • actions      → intrinsic width (NEVER wrapped in Expanded)
///
/// Phone (<600): everything stacked vertically; the primary action fills the
/// row. Tablet/Desktop (≥600): a single horizontal row with the three zones
/// above; actions keep their natural width and sit right-aligned.
class _WorkerPayrollTile extends StatefulWidget {
  final WorkerModel worker;
  final PayrollModel? payroll;
  final VoidCallback onGenerate;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onDelete;
  final VoidCallback? onDownloadPayslip;

  const _WorkerPayrollTile({
    required this.worker,
    required this.payroll,
    required this.onGenerate,
    this.onMarkPaid,
    this.onDelete,
    this.onDownloadPayslip,
  });

  @override
  State<_WorkerPayrollTile> createState() => _WorkerPayrollTileState();
}

class _WorkerPayrollTileState extends State<_WorkerPayrollTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.payroll;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    final workerInfo = Expanded(
      flex: 4,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: Text(
              widget.worker.name.isNotEmpty
                  ? widget.worker.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // The name Text lives inside this Expanded, so it always receives a
          // real width and can never wrap vertically (one glyph per line).
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.worker.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.worker.trade,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${CurrencyText.format(widget.worker.dailyRate)} / day',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (p != null) ...[
                  const SizedBox(height: 6),
                  StatusBadge(status: p.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final values = Expanded(
      flex: 3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _AmountColumn(label: 'Gross', value: p?.grossSalary),
          _AmountColumn(label: 'Advance', value: p?.advanceAmount),
          _AmountColumn(label: 'Net', value: p?.netSalary, bold: true),
        ],
      ),
    );

    final actions = _buildActions(context, isWide: isWide);

    return Card(
      elevation: _hover ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          onTap: widget.onGenerate,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      workerInfo,
                      const SizedBox(width: 16),
                      values,
                      const SizedBox(width: 16),
                      actions,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          workerInfo,
                          if (p != null) ...[
                            const SizedBox(width: 12),
                            StatusBadge(status: p.status),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      values,
                      const SizedBox(height: 12),
                      actions,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, {required bool isWide}) {
    final p = widget.payroll;
    final primary = p == null
        ? FilledButton.icon(
            onPressed: widget.onGenerate,
            icon: const Icon(Icons.auto_graph_rounded, size: 18),
            label: const Text('Generate'),
            style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
          )
        : FilledButton.icon(
            onPressed: widget.onGenerate,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View'),
            style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
          );

    final secondary = <Widget>[
      if (p != null)
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
          tooltip: 'Download Payslip (PDF)',
          onPressed: widget.onDownloadPayslip,
          visualDensity: VisualDensity.compact,
        ),
      if (p != null)
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Delete',
          onPressed: widget.onDelete,
          visualDensity: VisualDensity.compact,
        ),
      if (p != null && p.isDraft)
        IconButton(
          icon: const Icon(Icons.check_circle_outline, size: 20),
          tooltip: 'Mark Paid',
          onPressed: widget.onMarkPaid,
          visualDensity: VisualDensity.compact,
        ),
    ];

    if (!isWide) {
      // Phone: primary fills the row; secondary actions sit in a tight row
      // beneath it, right aligned.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: double.infinity, child: primary),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: secondary,
            ),
          ],
        ],
      );
    }
    // Tablet / Desktop: intrinsic-width actions, right aligned.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [primary, ...secondary],
    );
  }
}

/// Right-aligned amount column. Wrapped in [Expanded] so the three columns
/// share the values zone proportionally and stay aligned without magic widths.
class _AmountColumn extends StatelessWidget {
  final String label;
  final double? value;
  final bool bold;
  const _AmountColumn({
    required this.label,
    this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          value == null
              ? Text(
                  '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                )
              : CurrencyText(
                  value!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: bold ? cs.primary : null,
                  ),
                ),
        ],
      ),
    );
  }
}

class _PayrollEditDialog extends StatefulWidget {
  final WorkerModel worker;
  final PayrollModel payroll;
  final DateTime month;

  const _PayrollEditDialog({
    required this.worker,
    required this.payroll,
    required this.month,
  });

  @override
  State<_PayrollEditDialog> createState() => _PayrollEditDialogState();
}

class _PayrollEditDialogState extends State<_PayrollEditDialog> {
  final _overtimeHours = TextEditingController();
  final _bonus = TextEditingController();
  final _deductions = TextEditingController();
  final _notes = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _overtimeHours.text = widget.payroll.overtimeHours > 0
        ? widget.payroll.overtimeHours.toStringAsFixed(1)
        : '';
    _bonus.text =
        widget.payroll.bonus > 0 ? widget.payroll.bonus.toStringAsFixed(0) : '';
    _deductions.text = widget.payroll.deductions > 0
        ? widget.payroll.deductions.toStringAsFixed(0)
        : '';
    _notes.text = widget.payroll.notes ?? '';
  }

  @override
  void dispose() {
    _overtimeHours.dispose();
    _bonus.dispose();
    _deductions.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _otHours => double.tryParse(_overtimeHours.text.trim()) ?? 0.0;
  double get _bonusAmt => double.tryParse(_bonus.text.trim()) ?? 0.0;
  double get _deductionsAmt =>
      double.tryParse(_deductions.text.trim()) ?? 0.0;

  double get _baseWage => widget.payroll.baseWage;
  double get _otPay => _otHours * widget.payroll.overtimeRate;
  double get _gross => _baseWage + _otPay + _bonusAmt;
  double get _net => _gross - widget.payroll.advanceAmount - _deductionsAmt;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final net = _net < 0 ? 0.0 : _net;
    final updated = widget.payroll.copyWith(
      overtimeHours: _otHours,
      bonus: _bonusAmt,
      deductions: _deductionsAmt,
      netSalary: net,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      updatedAt: DateTime.now(),
    );

    final prov = context.read<WorkerProvider>();
    final ok = await prov.savePayroll(updated);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Failed to save payroll'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthName =
        '${_monthNames[widget.month.month - 1]} ${widget.month.year}';

    return AlertDialog(
      // Long worker/month titles must wrap/ellipsize instead of clipping on
      // narrow phones (320–412dp).
      title: Text(
        '${widget.worker.name} - $monthName',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Auto-filled read-only summary ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                        'Daily Wage (${widget.payroll.fullDays} full + ${widget.payroll.halfDays} half)',
                        CurrencyText.format(_baseWage)),
                    _SummaryRow('Daily Rate',
                        CurrencyText.format(widget.payroll.dailyRate)),
                    _SummaryRow('Advance Deducted',
                        CurrencyText.format(widget.payroll.advanceAmount)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Editable fields ──
              TextFormField(
                controller: _overtimeHours,
                decoration: InputDecoration(
                  labelText: 'Overtime Hours',
                  prefixIcon: const Icon(Icons.schedule_outlined),
                  helperText: widget.payroll.overtimeRate > 0
                      ? 'Rate: Rs. ${widget.payroll.overtimeRate.toStringAsFixed(0)}/hr'
                      : 'Set overtime rate on worker profile',
                  suffixText: 'hrs',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final v = double.tryParse(value.trim());
                    if (v == null || v < 0) return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bonus,
                decoration: const InputDecoration(
                  labelText: 'Bonus',
                  prefixIcon: Icon(Icons.card_giftcard_outlined),
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final v = double.tryParse(value.trim());
                    if (v == null || v < 0) return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deductions,
                decoration: const InputDecoration(
                  labelText: 'Deductions',
                  prefixIcon: Icon(Icons.remove_circle_outline),
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final v = double.tryParse(value.trim());
                    if (v == null || v < 0) return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ── Live net salary preview ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _SummaryRow('Overtime Pay ($_otHours hrs)',
                        CurrencyText.format(_otPay)),
                    _SummaryRow('Gross Salary', CurrencyText.format(_gross)),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Salary',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        CurrencyText(
                          _net < 0 ? 0.0 : _net,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_net < 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '⚠️ Deductions exceed gross — net clamped to 0',
                        style: TextStyle(fontSize: 11, color: cs.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(widget.payroll.id != null ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  static const _monthNames = [
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              )),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
