import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leave_request_model.dart';
import '../leave_provider.dart';

class LeaveFormScreen extends StatefulWidget {
  final LeaveRequestModel? leave;
  final String? userId;
  final String? siteId;

  const LeaveFormScreen({
    super.key,
    this.leave,
    this.userId,
    this.siteId,
  });

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late LeaveRequestModel _leave;
  late LeaveProvider _provider;
  late LeaveType _selectedType = LeaveType.annual;
  double _duration = 1.0;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _leave = widget.leave ?? LeaveRequestModel(
      uuid: '',
      userId: widget.userId ?? '',
      siteId: widget.siteId ?? '',
      date: DateTime.now(),
      type: LeaveType.annual,
      reason: '',
      duration: 1.0,
      status: LeaveSyncStatus.local,
      localPath: '',
      storagePath: '',
      hash: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _provider = LeaveProvider();
    _reasonController.text = _leave.reason;
  }

  @override
  void dispose() {
    _provider.onUserMutate();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.leave != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Leave' : 'New Leave'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLeave,
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
              // Leave type selection
              DropdownButtonFormField<LeaveType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                ),
                items: LeaveType.values.map((LeaveType type) {
                  return DropdownMenuItem<LeaveType>(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (LeaveType? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedType = newValue);
                  }
                },
                validator: (value) => value == null ? 'Select a type' : null,
              ),
              const SizedBox(height: 16),

              // Date field
              ListTile(
                title: const Text('Date'),
                trailing: Text(
                  '${_leave.date.year}/${_leave.date.month}/${_leave.date.day}',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _leave.date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != _leave.date) {
                    setState(() {
                      _leave = _leave.copyWith(date: picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Leave type display
              DropdownButtonFormField<LeaveType>(
                value: _leave.type,
                decoration: const InputDecoration(
                  labelText: 'Leave Type (saved)',
                  border: OutlineInputBorder(),
                ),
                items: LeaveType.values.map((LeaveType type) {
                  return DropdownMenuItem<LeaveType>(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (LeaveType? newValue) {
                  if (newValue != null) {
                    setState(() => _leave = _leave.copyWith(type: newValue));
                  }
                },
              ),
              const SizedBox(height: 16),

              // Duration
              ListTile(
                title: const Text('Duration (days)'),
                trailing: Text(_duration.toStringAsFixed(1)),
                onTap: () async {
                  final double? picked = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Duration'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Days'),
                            initialValue: _duration.toString(),
                            onChanged: (value) {
                              setState(() => _duration = double.tryParse(value) ?? 1.0);
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, _duration),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  if (picked != null) {
                    setState(() => _duration = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                initialValue: _leave.reason,
                onChanged: (value) {
                  setState(() {
                    _leave = _leave.copyWith(reason: value);
                    _reasonController.value = _reasonController.copyWith(
                      text: value,
                      selection: TextSelection.collapsed(offset: value.length),
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveLeave() async {
    if (!_formKey.currentState!.validate()) return;

    _leave = _leave.copyWith(
      duration: _duration,
      reason: _reasonController.text,
      updatedAt: DateTime.now(),
    );

    if (widget.leave == null) {
      await _provider.createLeave(
        userId: _leave.userId,
        siteId: _leave.siteId,
        date: _leave.date,
        type: _leave.type,
        reason: _leave.reason,
        duration: _leave.duration,
      );
    } else {
      await _provider.updateLeave(
        uuid: widget.leave!.uuid,
        reason: _leave.reason,
        duration: _leave.duration,
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
      _provider.onUserMutate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave saved')),
      );
    }
  }
}