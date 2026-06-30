import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/worker_model.dart';
import '../../core/providers/worker_provider.dart';

class WorkerFormScreen extends StatefulWidget {
  final int? workerId;

  const WorkerFormScreen({this.workerId, super.key});

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _dailyRate = TextEditingController();
  String _trade = AppConstants.trades.first;
  String _status = AppConstants.workerStatusActive;
  bool _loading = false;
  bool _initialLoad = false;
  WorkerModel? _original;

  bool get _isEditing => widget.workerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadWorker();
  }

  Future<void> _loadWorker() async {
    setState(() => _initialLoad = true);
    final worker =
        await context.read<WorkerProvider>().getWorker(widget.workerId!);
    if (worker != null && mounted) {
      _original = worker;
      _name.text = worker.name;
      _phone.text = worker.phone;
      _trade = AppConstants.trades.contains(worker.trade)
          ? worker.trade
          : AppConstants.trades.first;
      _dailyRate.text = worker.dailyRate.toStringAsFixed(0);
      _status = worker.status;
    }
    if (mounted) setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dailyRate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final provider = context.read<WorkerProvider>();
    final worker = WorkerModel(
      id: _original?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      trade: _trade,
      dailyRate: double.tryParse(_dailyRate.text.trim()) ?? 0,
      status: _status,
      createdAt: _original?.createdAt ?? DateTime.now(),
    );

    final ok = _isEditing
        ? await provider.updateWorker(worker)
        : await provider.addWorker(worker);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEditing ? 'Worker updated!' : 'Worker added!')),
      );
      context.go('/workers');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.error ?? 'Failed to save worker'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Worker' : 'Add New Worker'),
        leading: BackButton(onPressed: () => context.go('/workers')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'Worker Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Worker Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Worker name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _trade,
                    decoration: const InputDecoration(
                      labelText: 'Trade',
                      prefixIcon: Icon(Icons.construction_outlined),
                    ),
                    items: AppConstants.trades
                        .map((trade) => DropdownMenuItem(
                              value: trade,
                              child: Text(trade),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _trade = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dailyRate,
                    decoration: const InputDecoration(
                      labelText: 'Daily Rate *',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final rate = double.tryParse(value?.trim() ?? '');
                      if (rate == null || rate <= 0) {
                        return 'Enter a valid daily rate';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AppConstants.workerStatusActive,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.workerStatusInactive,
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _loading
                          ? 'Saving...'
                          : (_isEditing ? 'Update Worker' : 'Add Worker'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
