import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shifts/models/shift_model.dart';
import '../../shifts/shift_provider.dart';

class ShiftFormScreen extends StatefulWidget {
  final ShiftModel? shift;
  final String? userId;
  final String? siteId;

  const ShiftFormScreen({
    super.key,
    this.shift,
    this.userId,
    this.siteId,
  });

  @override
  State<ShiftFormScreen> createState() => _ShiftFormScreenState();
}

class _ShiftFormScreenState extends State<ShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ShiftModel _shift;
  late ShiftProvider _provider;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _shift = widget.shift ?? ShiftModel(
      uuid: '',
      userId: widget.userId ?? '',
      siteId: widget.siteId ?? '',
      date: DateTime.now(),
      startTime: TimeOfDay.now(),
      endTime: TimeOfDay.now(),
      kind: ShiftKind.regular,
      status: ShiftSyncStatus.local,
      localPath: '',
      storagePath: '',
      hash: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _provider = ShiftProvider();
  }

  @override
  void dispose() {
    _provider.onUserMutate();
    super.dispose();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() => _endTime = picked);
    }
  }

  String _getKindLabel(ShiftKind kind) {
    switch (kind) {
      case ShiftKind.regular:
        return 'Regular';
      case ShiftKind.overtime:
        return 'Overtime';
      case ShiftKind.breakShift:
        return 'Break';
      default:
        return 'Regular';
    }
  }

  ShiftKind _getKindFromLabel(String label) {
    switch (label) {
      case 'Overtime':
        return ShiftKind.overtime;
      case 'Break':
        return ShiftKind.breakShift;
      default:
        return ShiftKind.regular;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.shift != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Shift' : 'New Shift'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveShift,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Shift kind selection
              DropdownButtonFormField<ShiftKind>(
                value: _shift.kind,
                decoration: const InputDecoration(
                  labelText: 'Shift Kind',
                  border: OutlineInputBorder(),
                ),
                items: ShiftKind.values.map((ShiftKind kind) {
                  return DropdownMenuItem<ShiftKind>(
                    value: kind,
                    child: Text(_getKindLabel(kind)),
                  );
                }).toList(),
                onChanged: (ShiftKind? newValue) {
                  if (newValue != null) {
                    setState(() => _shift = _shift.copyWith(kind: newValue));
                  }
                },
                validator: (value) => value == null ? 'Select a kind' : null,
              ),
              const SizedBox(height: 16),

              // Date field
              ListTile(
                title: const Text('Date'),
                trailing: Text(
                  '${_shift.date.year}/${_shift.date.month}/${_shift.date.day}',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _shift.date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != _shift.date) {
                    setState(() {
                      _shift = _shift.copyWith(date: picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Start time
              ListTile(
                title: Text('Start Time: ${_startTime.format(context)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectStartTime(context),
                ),
              ),
              const SizedBox(height: 8),

              // End time
              ListTile(
                title: Text('End Time: ${_endTime.format(context)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectEndTime(context),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                initialValue: _shift.notes,
                onChanged: (value) {
                  setState(() => _shift = _shift.copyWith(notes: value));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}