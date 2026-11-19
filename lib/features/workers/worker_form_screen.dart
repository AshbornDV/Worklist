import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  final _overtimeRate = TextEditingController();
  final _address = TextEditingController();
  final _skills = TextEditingController();
  final _notes = TextEditingController();
  String _trade = AppConstants.trades.first;
  String _status = AppConstants.workerStatusActive;
  DateTime? _joinDate;
  File? _photoFile;
  String? _photoPath;
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
      _overtimeRate.text =
          worker.overtimeRate > 0 ? worker.overtimeRate.toStringAsFixed(0) : '';
      _status = worker.status;
      _address.text = worker.address ?? '';
      _skills.text = worker.skills ?? '';
      _notes.text = worker.notes ?? '';
      _joinDate = worker.joinDate;
      _photoPath = worker.photoPath;
    }
    if (mounted) setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dailyRate.dispose();
    _overtimeRate.dispose();
    _address.dispose();
    _skills.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null && mounted) {
      setState(() {
        _photoFile = File(pickedFile.path);
        _photoPath = pickedFile.path;
      });
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _photoFile = null;
      _photoPath = null;
    });
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
      overtimeRate: double.tryParse(_overtimeRate.text.trim()) ?? 0.0,
      status: _status,
      createdAt: _original?.createdAt ?? DateTime.now(),
      photoPath: _photoPath,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      skills: _skills.text.trim().isEmpty ? null : _skills.text.trim(),
      joinDate: _joinDate,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Worker' : 'Add New Worker')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // Keep the focused field visible above the on-screen keyboard.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Worker' : 'Add New Worker'),
        leading: BackButton(onPressed: () => context.go('/workers')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'Photo'),
                  const SizedBox(height: 12),
                  _PhotoSection(
                    photoPath: _photoPath,
                    photoFile: _photoFile,
                    onPickPhoto: _pickPhoto,
                    onRemovePhoto: _removePhoto,
                  ),
                  const SizedBox(height: 24),
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
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
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
                    controller: _skills,
                    decoration: const InputDecoration(
                      labelText: 'Skills',
                      prefixIcon: Icon(Icons.build_outlined),
                    ),
                    maxLines: 2,
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
                  TextFormField(
                    controller: _overtimeRate,
                    decoration: const InputDecoration(
                      labelText: 'Overtime Rate (per hour)',
                      prefixIcon: Icon(Icons.schedule_outlined),
                      helperText: 'Optional. Used in payroll calculations.',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final rate = double.tryParse(value.trim());
                        if (rate == null || rate < 0) {
                          return 'Enter a valid rate or leave empty';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _joinDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && mounted) {
                        setState(() => _joinDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Join Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _joinDate != null
                            ? '${_joinDate!.year}-${_joinDate!.month.toString().padLeft(2, '0')}-${_joinDate!.day.toString().padLeft(2, '0')}'
                            : 'Select join date',
                      ),
                    ),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                    maxLines: 3,
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

class _PhotoSection extends StatelessWidget {
  final String? photoPath;
  final File? photoFile;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  const _PhotoSection({
    required this.photoPath,
    required this.photoFile,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null || photoFile != null;

    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? (photoFile != null
                      ? Image.file(
                          photoFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person_outline, size: 60),
                        )
                      : Image.file(
                          File(photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person_outline, size: 60),
                        ))
                  : const Icon(Icons.person_outline, size: 60),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasPhoto) ...[
                OutlinedButton.icon(
                  onPressed: onRemovePhoto,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: onPickPhoto,
                icon: const Icon(Icons.photo_library),
                label: Text(hasPhoto ? 'Change' : 'Add Photo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
