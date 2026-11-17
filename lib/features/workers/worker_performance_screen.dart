import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/worker_performance_model.dart';
import '../../core/providers/worker_provider.dart';

class WorkerPerformanceScreen extends StatefulWidget {
  final int workerId;
  final String workerName;

  const WorkerPerformanceScreen({
    required this.workerId,
    required this.workerName,
    super.key,
  });

  @override
  State<WorkerPerformanceScreen> createState() => _WorkerPerformanceScreenState();
}

class _WorkerPerformanceScreenState extends State<WorkerPerformanceScreen> {
  List<WorkerPerformance> _performanceHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    setState(() => _loading = true);
    final history = await context
        .read<WorkerProvider>()
        .getWorkerPerformance(widget.workerId);
    if (mounted) {
      setState(() {
        _performanceHistory = history;
        _loading = false;
      });
    }
  }

  Future<void> _addPerformance() async {
    final prov = context.read<WorkerProvider>();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    
    final existing =
        await prov.getWorkerPerformanceForMonth(widget.workerId, month);

    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Performance for ${existing.monthLabel} already exists'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _PerformanceDialog(
        workerId: widget.workerId,
        month: month,
      ),
    );

    if (result == true && mounted) {
      await _loadPerformance();
    }
  }

  Future<void> _editPerformance(WorkerPerformance performance) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _PerformanceDialog(
        workerId: widget.workerId,
        month: performance.month,
        existing: performance,
      ),
    );

    if (result == true && mounted) {
      await _loadPerformance();
    }
  }

  Future<void> _deletePerformance(WorkerPerformance performance) async {
    final prov = context.read<WorkerProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Performance Record'),
        content: Text(
          'Are you sure you want to delete the performance record for ${performance.monthLabel}?',
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

    final success = await prov.deleteWorkerPerformance(performance.id!);

    if (!mounted) return;

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance record deleted')),
        );
        await _loadPerformance();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete performance record')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.workerName} - Performance',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: BackButton(onPressed: () => context.go('/workers')),
        actions: [
          IconButton(
            onPressed: _addPerformance,
            icon: const Icon(Icons.add),
            tooltip: 'Add Performance',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _performanceHistory.isEmpty
              ? _EmptyState(onAdd: _addPerformance)
              : _buildPerformanceList(),
    );
  }

  Widget _buildPerformanceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _performanceHistory.length,
      itemBuilder: (context, index) {
        final performance = _performanceHistory[index];
        return _PerformanceCard(
          performance: performance,
          onEdit: () => _editPerformance(performance),
          onDelete: () => _deletePerformance(performance),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No performance records yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Performance Record'),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final WorkerPerformance performance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PerformanceCard({
    required this.performance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  performance.monthLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Attendance',
                  value: '${performance.attendancePercentage.toStringAsFixed(1)}%',
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 16),
                _StatItem(
                  icon: Icons.access_time_outlined,
                  label: 'Late Arrivals',
                  value: '${performance.lateArrivals}',
                  color: const Color(0xFFF57C00),
                ),
                const SizedBox(width: 16),
                _StatItem(
                  icon: Icons.work_outline,
                  label: 'Completed Days',
                  value: '${performance.completedWorkDays}',
                  color: const Color(0xFF0288D1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  performance.ratingStars,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${performance.rating.toStringAsFixed(1)})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceDialog extends StatefulWidget {
  final int workerId;
  final DateTime month;
  final WorkerPerformance? existing;

  const _PerformanceDialog({
    required this.workerId,
    required this.month,
    this.existing,
  });

  @override
  State<_PerformanceDialog> createState() => _PerformanceDialogState();
}

class _PerformanceDialogState extends State<_PerformanceDialog> {
  final _attendancePercentage = TextEditingController();
  final _lateArrivals = TextEditingController();
  final _completedWorkDays = TextEditingController();
  final _rating = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _attendancePercentage.text =
          widget.existing!.attendancePercentage.toStringAsFixed(1);
      _lateArrivals.text = widget.existing!.lateArrivals.toString();
      _completedWorkDays.text = widget.existing!.completedWorkDays.toString();
      _rating.text = widget.existing!.rating.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _attendancePercentage.dispose();
    _lateArrivals.dispose();
    _completedWorkDays.dispose();
    _rating.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final performance = WorkerPerformance(
      id: widget.existing?.id,
      workerId: widget.workerId,
      month: widget.month,
      attendancePercentage:
          double.tryParse(_attendancePercentage.text.trim()) ?? 0.0,
      lateArrivals: int.tryParse(_lateArrivals.text.trim()) ?? 0,
      completedWorkDays: int.tryParse(_completedWorkDays.text.trim()) ?? 0,
      rating: double.tryParse(_rating.text.trim()) ?? 0.0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<WorkerProvider>();
    final success = widget.existing != null
        ? await provider.updateWorkerPerformance(performance)
        : await provider.addWorkerPerformance(performance);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save performance'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Performance' : 'Add Performance'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Month: ${widget.month.year}-${widget.month.month.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _attendancePercentage,
                decoration: const InputDecoration(
                  labelText: 'Attendance Percentage *',
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final pct = double.tryParse(value?.trim() ?? '');
                  if (pct == null || pct < 0 || pct > 100) {
                    return 'Enter a value between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lateArrivals,
                decoration: const InputDecoration(
                  labelText: 'Late Arrivals',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final count = int.tryParse(value?.trim() ?? '');
                  if (count != null && count < 0) {
                    return 'Cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _completedWorkDays,
                decoration: const InputDecoration(
                  labelText: 'Completed Work Days',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final days = int.tryParse(value?.trim() ?? '');
                  if (days != null && days < 0) {
                    return 'Cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rating,
                decoration: const InputDecoration(
                  labelText: 'Rating *',
                  helperText: '1.0 to 5.0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final rating = double.tryParse(value?.trim() ?? '');
                  if (rating == null || rating < 1 || rating > 5) {
                    return 'Enter a value between 1.0 and 5.0';
                  }
                  return null;
                },
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
