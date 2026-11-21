import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'daily_report_provider.dart';

class ReportListScreen extends StatefulWidget {
  final String userId;

  const ReportListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  late final DailyReportProvider _provider;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _provider = DailyReportProvider(
      db: context.read<DatabaseHelper>(),
      firebase: context.read<FirebaseService>(),
      sync: context.read<SyncService>(),
      userId: widget.userId,
    );
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _provider.refresh();
    setState(() => _isLoading = false);
  }

  Future<void> _syncReport(DailyReportModel report) async {
    setState(() => _isLoading = true);
    await _provider.syncReport(report);
    setState(() => _isLoading = false);
  }

  Future<void> _exportReportPdf(DailyReportModel report) async {
    setState(() => _isLoading = true);
    try {
      final pdfBytes = await _provider.exportReportPdf(report.uuid);
      // TODO: Show local notification or share PDF
    } catch (e) {
      // TODO: Show error dialog
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteReport(DailyReportModel report) async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
            'Are you sure you want to delete this daily report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      setState(() => _isLoading = true);
      await _provider.deleteReport(report);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _isLoading ? null : () => _syncReport(_provider._selectedReport ?? _provider.reports.firstWhereOrNull((r) => !r.isDeleted)),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: _isLoading ? null : _exportReportPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _provider.reports.length,
                itemBuilder: (context, index) {
                  final report = _provider.reports[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      title: Text(
                        report.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        '${report.siteName} • ${report.date}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            report.isDeleted
                                ? Icons.delete_outline
                                : Icons.remove_circle_outline,
                            color: report.isDeleted ? Colors.red : null,
                          ),
                          if (!report.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.sync),
                              onPressed: () => _syncReport(report),
                            ),
                          if (!report.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteReport(report),
                              tooltip: 'Delete',
                            ),
                        ],
                      ),
                      onTap: () {
                        // Navigate to form screen for editing
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportFormScreen(
                              date: report.date,
                              site: report.site,
                              reportUuid: report.uuid,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}