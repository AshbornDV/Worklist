/// Document Management — detail / viewer screen.
///
/// Shows a full preview (image lightbox, PDF/DOCX/XLSX via system viewer),
/// metadata, sync status + upload progress, and all actions (rename, replace,
/// soft-delete, restore, purge, version history). Responsive + M3.
library;

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../models/document_model.dart';
import '../providers/document_provider.dart';
import '../services/document_file_service.dart';
import '../widgets/document_thumbnail.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.doc});
  final DocumentModel doc;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final double _progress = 0;
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      final provider = context.read<DocumentProvider>();
      debugPrint('[Docs:detail] open requested uuid=${widget.doc.uuid}');
      final file = await provider.ensureLocal(widget.doc);
      if (file == null) {
        debugPrint('[Docs:detail] open aborted: binary missing locally');
        if (mounted) await _showMissingDialog(provider);
        return;
      }
      debugPrint('[Docs:detail] opening ${file.path}');
      final result = await OpenFile.open(file.path);
      debugPrint('[Docs:detail] open result ${result.type} ${result.message}');
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open: ${result.message}')),
        );
      }
    } catch (e) {
      debugPrint('[Docs:detail] open exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Cannot open: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// PART 6 — binary missing on this device. Never hang; offer recovery.
  Future<void> _showMissingDialog(DocumentProvider provider) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('File unavailable on this device'),
        content: const Text(
          'The document metadata exists, but its file is not stored on this '
          'device. You can remove the metadata, or attach a replacement file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'remove'),
            child: const Text('Remove metadata'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: const Text('Replace file'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'remove') {
      await provider.softDelete(widget.doc);
      if (mounted) Navigator.of(context).pop();
    } else if (choice == 'replace') {
      await _importReplacement();
    }
  }

  Future<void> _rename() async {
    final ctrl = TextEditingController(text: widget.doc.fileName);
    final provider = context.read<DocumentProvider>();
    final navigator = Navigator.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'File name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await provider.rename(widget.doc, name);
      if (!mounted) return;
      navigator.pop();
    }
  }

  Future<void> _replace() async {
    final provider = context.read<DocumentProvider>();
    // Reuse the file picker through the provider's public path.
    await provider.pickFiles(
      context: context,
      entityType: widget.doc.entityType,
      entityId: widget.doc.entityId,
      category: widget.doc.category,
      multiple: false,
    );
    // pickFiles inserts a NEW version already; nothing else to do here.
  }

  /// Cross-device recovery: a document whose binary is missing locally can be
  /// re-attached from a local file (re-ingested as a new version).
  Future<void> _importReplacement() async {
    final provider = context.read<DocumentProvider>();
    final count = await provider.pickFiles(
      context: context,
      entityType: widget.doc.entityType,
      entityId: widget.doc.entityId,
      category: widget.doc.category,
      multiple: false,
    );
    if (count > 0 && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final provider = context.read<DocumentProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: const Text('The document stays recoverable in Trash.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.softDelete(widget.doc);
      if (!mounted) return;
      navigator.pop();
    }
  }

  Future<void> _restore() async {
    await context.read<DocumentProvider>().restore(widget.doc);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _purge() async {
    final provider = context.read<DocumentProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently delete?'),
        content: const Text('This removes the file everywhere. Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.purge(widget.doc);
      if (!mounted) return;
      navigator.pop();
    }
  }

  void _showVersions(DocumentProvider provider) {
    final chain = provider.versionHistory(widget.doc);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const ListTile(title: Text('Version history')),
          for (final v in chain)
            ListTile(
              leading: DocumentThumbnail(doc: v, size: 40),
              title: Text('Version ${v.version}'),
              subtitle: Text(
                '${v.fileName} · ${(v.sizeBytes / 1024).toStringAsFixed(1)} KB',
              ),
              trailing: v.uuid == widget.doc.uuid
                  ? const Chip(label: Text('current'))
                  : null,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final isWide = MediaQuery.of(context).size.width >= 840;
    final preview = doc.isImage
        ? _ImagePreview(doc: doc)
        : _FilePreview(doc: doc);

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: isWide ? 3 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              preview,
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _open,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open / Preview'),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
        if (isWide) const SizedBox(width: 24),
        if (isWide)
          Expanded(
            flex: 2,
            child: _Meta(doc: doc, progress: _progress),
          ),
      ],
    );

    return Consumer<DocumentProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: Text(doc.fileName, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_outlined),
              tooltip: 'Version history',
              onPressed: () => _showVersions(provider),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isWide) ...[
                    preview,
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _open,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open / Preview'),
                    ),
                    const SizedBox(height: 16),
                    _Meta(doc: doc, progress: _progress),
                    const SizedBox(height: 16),
                  ] else
                    body,
                  const SizedBox(height: 16),
                  _Actions(
                    doc: doc,
                    onRename: _rename,
                    onReplace: _replace,
                    onDelete: _delete,
                    onRestore: _restore,
                    onPurge: _purge,
                    onImportReplacement: _importReplacement,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.doc});
  final DocumentModel doc;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _resolve(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _placeholder(
            context,
            child: const CircularProgressIndicator(),
          );
        }
        final file = snap.data;
        if (file == null) {
          return _placeholder(
            context,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, size: 48),
                SizedBox(height: 8),
                Text('File unavailable on this device.'),
              ],
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              height: 360,
              errorBuilder: (_, __, ___) => _placeholder(
                context,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_outlined, size: 48),
                    SizedBox(height: 8),
                    Text('Image could not be displayed.'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context, {required Widget child}) =>
      Container(
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      );

  Future<File?> _resolve() async {
    try {
      if (await DocumentFileService.instance.existsLocally(doc)) {
        return await DocumentFileService.instance.resolveFile(doc.localPath);
      }
    } catch (_) {}
    return null;
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.doc});
  final DocumentModel doc;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (doc.kind) {
      DocumentKind.pdf => 'PDF document',
      DocumentKind.docx => 'Word document',
      DocumentKind.xlsx => 'Spreadsheet',
      DocumentKind.image => 'Image',
      DocumentKind.unsupported => 'File',
    };
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DocumentThumbnail(doc: doc, size: 96),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Tap "Open / Preview" to view.'),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.doc, required this.progress});
  final DocumentModel doc;
  final double progress;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (doc.syncStatus) {
      DocumentSyncStatus.synced => Colors.green,
      DocumentSyncStatus.uploading => Colors.orange,
      DocumentSyncStatus.failed => Colors.red,
      DocumentSyncStatus.missingLocal => Colors.red,
      DocumentSyncStatus.pending => Colors.grey,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(context, 'Category', doc.category ?? '—'),
            _row(context, 'Type', _typeLabel(doc.entityType)),
            _row(context, 'Size', '${(doc.sizeBytes / 1024).toStringAsFixed(1)} KB'),
            _row(context, 'Version', '${doc.version}'),
            if (doc.hash != null)
              _row(context, 'SHA-256', '${doc.hash!.substring(0, 12)}…'),
            _row(context, 'Updated', doc.updatedAt.toLocal().toString().split('.')[0]),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 6),
                Text('Sync: ${doc.syncStatus.name}', style: theme.textTheme.labelMedium),
              ],
            ),
            if (doc.syncStatus == DocumentSyncStatus.uploading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: progress),
              ),
            if (doc.syncStatus == DocumentSyncStatus.failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final provider =
                        context.findAncestorStateOfType<_DocumentDetailScreenState>()
                            ?.context
                            .read<DocumentProvider>();
                    if (provider == null) return;
                    await provider.retryQueue();
                    if (nav.mounted) nav.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: Text(k,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            ),
            Expanded(child: Text(v, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );

  static String _typeLabel(DocumentEntityType t) => switch (t) {
        DocumentEntityType.worker => 'Worker',
        DocumentEntityType.site => 'Site',
        DocumentEntityType.product => 'Product',
        DocumentEntityType.payroll => 'Payroll',
        DocumentEntityType.payment => 'Payment',
        DocumentEntityType.service => 'Service',
      };
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.doc,
    required this.onRename,
    required this.onReplace,
    required this.onDelete,
    required this.onRestore,
    required this.onPurge,
    required this.onImportReplacement,
  });
  final DocumentModel doc;
  final VoidCallback onRename;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onPurge;
  final VoidCallback onImportReplacement;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
              onPressed: onRename, icon: const Icon(Icons.edit), label: const Text('Rename')),
          OutlinedButton.icon(
              onPressed: onReplace,
              icon: const Icon(Icons.upload),
              label: const Text('Replace')),
          // A document whose binary is missing on this device (e.g. created
          // elsewhere) can still be re-attached from local storage.
          if (doc.syncStatus == DocumentSyncStatus.missingLocal)
            FilledButton.icon(
              onPressed: onImportReplacement,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import replacement'),
            ),
          if (!doc.isDeleted)
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            )
          else ...[
            FilledButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore),
              label: const Text('Restore'),
            ),
            FilledButton.icon(
              onPressed: onPurge,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Purge'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      );
}