import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shifts/models/shift_model.dart';
import '../../shifts/shift_provider.dart';

class ShiftListScreen extends StatefulWidget {
  final String? userId;
  final String? siteId;

  const ShiftListScreen({
    super.key,
    this.userId,
    this.siteId,
  });

  @override
  State<ShiftListScreen> createState() => _ShiftListScreenState();
}

class _ShiftListScreenState extends State<ShiftListScreen> {
  late ShiftProvider _provider;
  late List<ShiftModel> _shifts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = ShiftProvider();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    setState(() => _isLoading = true);
    _shifts = await _provider.getShiftsByUser(
      userId: widget.userId!,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _refreshShifts() async {
    await _loadShifts();
    _provider.onUserMutate();
  }

  void _deleteShift(ShiftModel shift) async {
    await _provider.deleteShift(shift.uuid);
    _refreshShifts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shifts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to form screen
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshShifts,
              child: ListView.builder(
                itemCount: _shifts.length,
                itemBuilder: (context, index) {
                  final shift = _shifts[index];
                  return ListTile(
                    title: Text('${shift.kind} Shift'),
                    subtitle: Text(
                      '${shift.date.day}/${shift.date.month}/${shift.date.year} '
                      '${shift.startTime.format(context)} - ${shift.endTime.format(context)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sync, color: Colors.blue),
                          onPressed: () async {
                            await _provider.markShiftSynced(shift.uuid);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Shift synced')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteShift(shift),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}