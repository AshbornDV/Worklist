import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../../core/models/worker_document_model.dart';
import '../../core/providers/worker_provider.dart';

class WorkerDocumentsScreen extends StatefulWidget {
  final int workerId;
  final String workerName;

  const WorkerDocumentsScreen({
    required this.workerId,
    required this.workerName,
    super.key,
  });

  @override
  State<WorkerDocumentsScreen> createState() => _WorkerDocumentsScreenState();
}

class _WorkerDocumentsScreenState extends State<WorkerDocumentsScreen> {
  final _picker = ImagePicker();
  List<WorkerDocument> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    final docs = await context
        .read<WorkerProvider>()
        .getWorkerDocuments(widget.workerId);
    if (mounted) {
      setState(() {
        _documents = docs;
        _loading = false;
      });
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    try {
      final prov = context.read<WorkerProvider>();
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final document = WorkerDocument(
        workerId: widget.workerId,
        documentType: documentType,
        filePath: pickedFile.path,
        uploadedAt: DateTime.now(),
        fileName: pickedFile.name,
      );

      final success = await prov.addWorkerDocument(document);

      if (!mounted) return;

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')),
          );
          await _loadDocuments();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload document')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _previewDocument(WorkerDocument document) async {
    try {
      final result = await OpenFile.open(document.filePath);
      if (!mounted) return;

      if (result.type == ResultType.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(WorkerDocument document) async {
    final prov = context.read<WorkerProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete ${document.displayName}?'),
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

    final success = await prov.deleteWorkerDocument(document.id!);

    if (!mounted) return;

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
        await _loadDocuments();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete document')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.workerName} - Documents',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: BackButton(onPressed: () => context.go('/workers')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildDocumentList(),
    );
  }

  Widget _buildDocumentList() {
    final documentTypes = [
      'citizenship',
      'passport',
      'contract',
      'driving_license',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documentTypes.length,
      itemBuilder: (context, i) {
        final type = documentTypes[i];
        final documents = _documents.where((d) => d.documentType == type).toList();
        return _DocumentTypeCard(
          documentType: type,
          documents: documents,
          onUpload: () => _uploadDocument(type),
          onPreview: (doc) => _previewDocument(doc),
          onDelete: (doc) => _deleteDocument(doc),
        );
      },
    );
  }
}

class _DocumentTypeCard extends StatelessWidget {
  final String documentType;
  final List<WorkerDocument> documents;
  final VoidCallback onUpload;
  final Function(WorkerDocument) onPreview;
  final Function(WorkerDocument) onDelete;

  const _DocumentTypeCard({
    required this.documentType,
    required this.documents,
    required this.onUpload,
    required this.onPreview,
    required this.onDelete,
  });

  String get _displayName {
    switch (documentType) {
      case 'citizenship':
        return 'Citizenship';
      case 'passport':
        return 'Passport';
      case 'contract':
        return 'Contract';
      case 'driving_license':
        return 'Driving License';
      default:
        return documentType;
    }
  }

  IconData get _icon {
    switch (documentType) {
      case 'citizenship':
        return Icons.badge_outlined;
      case 'passport':
        return Icons.book_outlined;
      case 'contract':
        return Icons.description_outlined;
      case 'driving_license':
        return Icons.drive_eta_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: cs.primary),
                const SizedBox(width: 12),
                Text(
                  _displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (documents.isEmpty)
                  FilledButton.tonalIcon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload'),
                  ),
              ],
            ),
            if (documents.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...documents.map((doc) => _DocumentTile(
                    document: doc,
                    onPreview: () => onPreview(doc),
                    onDelete: () => onDelete(doc),
                    onUpload: onUpload,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final WorkerDocument document;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onUpload;

  const _DocumentTile({
    required this.document,
    required this.onPreview,
    required this.onDelete,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.fileName ?? 'Document',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Uploaded: ${document.uploadedAt.day}/${document.uploadedAt.month}/${document.uploadedAt.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onPreview,
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Preview',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
