import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leave_request_model.dart';
import '../leave_provider.dart';

class LeaveListScreen extends StatefulWidget {
  final String? userId;
  final String? siteId;

  const LeaveListScreen({
    super.key,
    this.userId,
    this.siteId,
  });

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  late LeaveProvider _provider;
  late List<LeaveRequestModel> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = LeaveProvider();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    final userId = widget.userId ?? '';
    final siteId = widget.siteId ?? '';
    final leaves = await _provider.getLeaves(userId: userId, siteId: siteId);
    setState(() {
      _leaves = leaves;
      _isLoading = false;
    });
  }

  Future<void> _refreshLeaves() async {
    await _loadLeaves();
    _provider.onUserMutate();
  }

  Future<void> _deleteLeave(String uuid) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Leave'),
        content: const Text('Are you sure you want to delete this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _provider.deleteLeave(uuid);
      _refreshLeaves();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveFormScreen(),
                ),
              ).then((_) => _refreshLeaves());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_note, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No leave requests found'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LeaveFormScreen(),
                            ),
                          );
                        },
                        child: const Text('Add New Leave Request'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _leaves.length,
                  itemBuilder: (context, index) {
                    final leave = _leaves[index];
                    final isSynced = leave.syncStatus == LeaveSyncStatus.synced;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text('${leave.type} - ${leave.date.toString().split(' ').first}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duration: ${leave.duration.toStringAsFixed(1)} days'),
                            Text('Reason: ${leave.reason}'),
                            Text(
                              'Status: ${leave.status.name}',
                              style: TextStyle(
                                color: isSynced ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isSynced)
                              IconButton(
                                icon: const Icon(Icons.cloud_sync, color: Colors.orange),
                                onPressed: () async {
                                  await _provider.syncLeave(leave.uuid);
                                  _refreshLeaves();
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteLeave(leave.uuid),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}