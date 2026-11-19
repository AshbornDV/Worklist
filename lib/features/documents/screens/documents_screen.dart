/// Document Management — main screen (list / grid, search, filter, trash).
///
/// Responsive: phone = 2-col grid + bottom FAB; tablet = 3–4 cols; desktop =
/// centered max-width layout with an inline "Add" menu. Dark/light aware,
/// Material 3. Supports a scoped mode (opened from an entity detail screen)
/// and a global mode (opened from the dashboard nav).
library;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/document_model.dart';
import '../providers/document_provider.dart';
import '../widgets/document_thumbnail.dart';
import 'document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    this.scopedType,
    this.scopedEntityId,
    this.scopedTitle,
  });
  final DocumentEntityType? scopedType;
  final int? scopedEntityId;
  final String? scopedTitle;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().load();
    });
  }

  Future<void> _showAdd(BuildContext context, DocumentProvider provider) async {
    final entityType = provider.filterType ?? DocumentEntityType.worker;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera capture'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('File picker (image / PDF / DOCX / XLSX)'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'camera') {
      if (!context.mounted) return;
      await provider.captureFromCamera(context: context, entityType: entityType);
    } else if (choice == 'file') {
      if (!context.mounted) return;
      await provider.pickFiles(context: context, entityType: entityType);
    }
  }

  /// PART 5 — grid context menu / long-press action dispatcher.
  Future<void> _handleAction(
    BuildContext context,
    DocumentModel doc,
    String action,
  ) async {
    final provider = context.read<DocumentProvider>();
    switch (action) {
      case 'menu':
        // Long-press: route to the detail screen (full action surface).
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DocumentDetailScreen(doc: doc)),
        );
      case 'open':
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DocumentDetailScreen(doc: doc)),
        );
      case 'rename':
        await _renameDialog(context, provider, doc);
      case 'category':
        await _categoryDialog(context, provider, doc);
      case 'replace':
        await provider.pickFiles(
          context: context,
          entityType: doc.entityType,
          entityId: doc.entityId,
          category: doc.category,
          multiple: false,
        );
      case 'delete':
        final ok = await _confirm(context, 'Delete document?',
            'Move "${doc.fileName}" to trash?');
        if (ok) await provider.softDelete(doc);
      case 'restore':
        await provider.restore(doc);
      case 'purge':
        final ok = await _confirm(context, 'Permanently delete?',
            'Remove "${doc.fileName}" everywhere. Cannot be undone.');
        if (ok) await provider.purge(doc);
    }
  }

  Future<void> _renameDialog(
    BuildContext context,
    DocumentProvider provider,
    DocumentModel doc,
  ) async {
    final ctrl = TextEditingController(text: doc.fileName);
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
      await provider.rename(doc, name);
    }
  }

  Future<void> _categoryDialog(
    BuildContext context,
    DocumentProvider provider,
    DocumentModel doc,
  ) async {
    final ctrl = TextEditingController(text: doc.category ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. ID Proof'),
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
    if (value != null) {
      await provider.setCategory(doc, value.isEmpty ? null : value);
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String body,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 840;
    final title = widget.scopedTitle ?? 'Documents';
    return ChangeNotifierProvider(
      create: (_) => DocumentProvider(
        scopedType: widget.scopedType,
        scopedEntityId: widget.scopedEntityId,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Trash',
              onPressed: () =>
                  context.read<DocumentProvider>().toggleTrash(),
            ),
          ],
        ),
        floatingActionButton: isWide
            ? null
            : FloatingActionButton.extended(
              onPressed: () =>
                  _showAdd(context, context.read<DocumentProvider>()),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
        body: Consumer<DocumentProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _Toolbar(
                  provider: provider,
                  isWide: isWide,
                  onAdd: () => _showAdd(context, provider),
                ),
                Expanded(
                  child: provider.loading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.docs.isEmpty
                          ? _Empty(showTrash: provider.showTrash)
                          : _Grid(provider: provider, onAction: _handleAction),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.provider,
    required this.isWide,
    required this.onAdd,
  });
  final DocumentProvider provider;
  final bool isWide;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const types = DocumentEntityType.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add document'),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search documents…',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: provider.setSearch,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: provider.filterType == null,
                  onSelected: (_) => provider.setFilterType(null),
                ),
                const SizedBox(width: 6),
                for (final t in types)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_typeLabel(t)),
                      selected: provider.filterType == t,
                      onSelected: (_) => provider.setFilterType(t),
                    ),
                  ),
                const SizedBox(width: 6),
                DropdownButton<DocumentSort>(
                  value: provider.sort,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                        value: DocumentSort.dateDesc, child: Text('Newest')),
                    DropdownMenuItem(
                        value: DocumentSort.dateAsc, child: Text('Oldest')),
                    DropdownMenuItem(
                        value: DocumentSort.nameAsc, child: Text('Name')),
                    DropdownMenuItem(
                        value: DocumentSort.sizeDesc, child: Text('Size')),
                  ],
                  onChanged: (v) => provider.setSort(v!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(DocumentEntityType t) => switch (t) {
        DocumentEntityType.worker => 'Workers',
        DocumentEntityType.site => 'Sites',
        DocumentEntityType.product => 'Products',
        DocumentEntityType.payroll => 'Payroll',
        DocumentEntityType.payment => 'Payments',
        DocumentEntityType.service => 'Services',
      };
}

class _Grid extends StatelessWidget {
  const _Grid({required this.provider, required this.onAction});
  final DocumentProvider provider;
  final void Function(BuildContext context, DocumentModel doc, String action)
      onAction;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cross = width >= 1200
        ? 5
        : width >= 840
            ? 4
            : width >= 600
                ? 3
                : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: provider.docs.length,
      itemBuilder: (context, i) {
        final doc = provider.docs[i];
        return _Tile(doc: doc, onAction: onAction);
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.doc, required this.onAction});
  final DocumentModel doc;
  final void Function(BuildContext context, DocumentModel doc, String action)
      onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DocumentDetailScreen(doc: doc)),
      ),
      onLongPress: () => onAction(context, doc, 'menu'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: DocumentThumbnail(doc: doc, size: 140)),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _SyncDot(doc: doc),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doc.category ?? _typeLabel(doc.entityType),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: PopupMenuButton<String>(
                  onSelected: (a) => onAction(context, doc, a),
                  itemBuilder: (_) => _menuItems(doc),
                  icon: const Icon(Icons.more_vert),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<PopupMenuEntry<String>> _menuItems(DocumentModel doc) => [
        const PopupMenuItem(value: 'open', child: Text('Open')),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'category', child: Text('Change category')),
        const PopupMenuItem(value: 'replace', child: Text('Replace file')),
        if (!doc.isDeleted)
          const PopupMenuItem(value: 'delete', child: Text('Delete'))
        else ...[
          const PopupMenuItem(value: 'restore', child: Text('Restore')),
          const PopupMenuItem(
              value: 'purge', child: Text('Permanently delete')),
        ],
      ];

  static String _typeLabel(DocumentEntityType t) => switch (t) {
        DocumentEntityType.worker => 'Worker',
        DocumentEntityType.site => 'Site',
        DocumentEntityType.product => 'Product',
        DocumentEntityType.payroll => 'Payroll',
        DocumentEntityType.payment => 'Payment',
        DocumentEntityType.service => 'Service',
      };
}

class _SyncDot extends StatelessWidget {
  const _SyncDot({required this.doc});
  final DocumentModel doc;
  @override
  Widget build(BuildContext context) {
    final color = switch (doc.syncStatus) {
      DocumentSyncStatus.synced => Colors.green,
      DocumentSyncStatus.uploading => Colors.orange,
      DocumentSyncStatus.failed => Colors.red,
      DocumentSyncStatus.missingLocal => Colors.red,
      DocumentSyncStatus.pending => Colors.grey,
    };
    return Tooltip(
      message: doc.syncStatus.name,
      child: Icon(Icons.circle, size: 8, color: color),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.showTrash});
  final bool showTrash;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_outlined,
                  size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(showTrash ? 'Trash is empty' : 'No documents yet'),
              const SizedBox(height: 4),
              Text(
                showTrash
                    ? 'Deleted documents will appear here.'
                    : 'Tap + to capture or attach a file.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}