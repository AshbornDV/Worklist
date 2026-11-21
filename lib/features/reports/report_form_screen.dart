import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../sites/models/site_model.dart';
import '../../sites/providers/site_provider.dart';
import 'daily_report_provider.dart';

class ReportFormScreen extends StatefulWidget {
  final String? reportUuid;
  final String date;
  final SiteModel site;

  const ReportFormScreen({
    super.key,
    required this.date,
    required this.site,
    this.reportUuid,
  });

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.reportUuid != null) {
      final provider = context.read<DailyReportProvider>();
      final report = provider.getReportByUuid(widget.reportUuid!);
      if (report != null) {
        _titleController.text = report.title;
        // Load content from storagePath if needed
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitReport(List<Uint8List> photos) async {
    setState(() => _isSubmitting = true);
    try {
      final provider = context.read<DailyReportProvider>();
      await provider.createReport(
        title: _titleController.text.trim(),
        date: widget.date,
        site: widget.site,
        photos: photos,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save report: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _capturePhoto() async {
    // Photo capture implementation using image_picker or camera
    // For now, placeholder for photo capture
    final List<Uint8List> photos = []; // populated from camera/gallery

    await _submitReport(photos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Daily Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _capturePhoto,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Site: ${widget.site.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${widget.date}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Report Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Content',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        alignVertical: Alignment.centerTop,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : () => _capturePhoto(),
        child: _isSubmitting
            ? const CircularProgressIndicator()
            : const Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : () => _submitReport([]),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: _isSubmitting ? 'Saving...' : 'Save Report',
        ),
      ),
    );
  }
}