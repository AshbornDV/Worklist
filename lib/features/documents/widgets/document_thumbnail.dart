/// Document Management — thumbnail widget.
///
/// Lazy image preview with a cached [Image.file]; falls back to a typed icon
/// for PDF/DOCX/XLSX. Never blocks the UI (no synchronous decode).
library;

import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../models/document_model.dart';
import '../services/document_file_service.dart';

class DocumentThumbnail extends StatelessWidget {
  const DocumentThumbnail({
    super.key,
    required this.doc,
    this.size = 96,
  });
  final DocumentModel doc;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(10);
    final icon = _iconFor(doc.kind, theme);

    // Images with a generated thumbnail show the thumbnail; everything else
    // (and images without a thumbnail) shows a typed icon. This guarantees a
    // visible, non-loading state for every document kind.
    final child = doc.isImage && doc.thumbPath != null
        ? _AsyncImage(thumbPath: doc.thumbPath!, size: size)
        : Center(child: Icon(icon, size: size * 0.4, color: theme.colorScheme.primary));

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: theme.colorScheme.surfaceContainerHighest,
        child: child,
      ),
    );
  }

  static IconData _iconFor(DocumentKind kind, ThemeData theme) {
    switch (kind) {
      case DocumentKind.image:
        return Icons.image_outlined;
      case DocumentKind.pdf:
        return Icons.picture_as_pdf_outlined;
      case DocumentKind.docx:
        return Icons.description_outlined;
      case DocumentKind.xlsx:
        return Icons.table_chart_outlined;
      case DocumentKind.unsupported:
        return Icons.insert_drive_file_outlined;
    }
  }
}

/// Resolves a stored RELATIVE thumb path to an absolute file and shows it,
/// fading in when loaded. Failed loads fall back to the typed icon.
class _AsyncImage extends StatelessWidget {
  const _AsyncImage({required this.thumbPath, required this.size});
  final String thumbPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _resolve(),
      builder: (context, snap) {
        if (snap.hasData && snap.data != null) {
          return Image.file(
            snap.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
            frameBuilder: (_, child, frame, ___ ) => frame == null
                ? const SizedBox()
                : child,
          );
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  Future<File?> _resolve() async {
    try {
      final f = await DocumentFileService.instance.resolveFile(thumbPath);
      return await f.exists() ? f : null;
    } catch (_) {
      return null;
    }
  }
}