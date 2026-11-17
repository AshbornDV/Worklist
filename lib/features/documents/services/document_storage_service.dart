/// Document Management — local-first storage service.
///
/// Binaries are stored on the device only:
///   • Android → application Documents directory
///   • Windows → application support directory
/// (resolved by [DocumentFileService]). Files use UUID filenames, SHA-256
/// hashing, relative paths and versioned, non-overwriting saves.
///
/// Document METADATA is synchronized to Firebase RTDB by the EXISTING
/// export/import pipeline ([DatabaseHelper.exportUserData] already includes the
/// `documents` table). This service never touches the sync architecture — it
/// only ever updates the local binary + the local `sync_status`/`storage_path`
/// columns.
///
/// [DocumentStorageService] is the single isolated seam for binary transport.
/// A future cloud backend (e.g. Firebase Storage) would replace ONLY the bodies
/// of [upload]/[download]/[deleteFromStorage] below — no other layer knows
/// whether a file lives locally or in the cloud.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/document_model.dart';
import '../repositories/document_repository.dart';
import 'document_file_service.dart';

class DocumentStorageService {
  DocumentStorageService._();
  static final DocumentStorageService instance = DocumentStorageService._();

  final _repo = DocumentRepository();
  final _files = DocumentFileService.instance;

  /// Persist a document's binary locally and mark its metadata synced.
  ///
  /// No network upload — the binary stays on device. Metadata propagates to
  /// RTDB through the existing export pipeline on the next cloud push.
  /// [onProgress] is invoked once at 1.0 to keep the caller's UX identical to
  /// a real transfer.
  Future<void> upload(
    DocumentModel doc, {
    required void Function(double progress)? onProgress,
  }) async {
    final file = await _files.resolveFile(doc.localPath);
    if (!await file.exists()) {
      throw const DocumentStorageException('Local file missing.');
    }
    // Recompute the hash so the stored digest always matches the bytes on disk.
    final hash = await _files.hashFile(file);
    onProgress?.call(1.0);
    final updated = doc.copyWith(
      storagePath: doc.localPath,
      hash: hash,
      syncStatus: DocumentSyncStatus.synced,
      updatedAt: DateTime.now(),
    );
    await _repo.update(updated);
  }

  /// Ensure a document's binary is available locally.
  ///
  /// Returns the local [File] when present, otherwise marks the document
  /// `missingLocal` and returns `null` (the UI shows "File unavailable on this
  /// device."). No network access.
  Future<File?> download(
    DocumentModel doc, {
    required void Function(double progress)? onProgress,
  }) async {
    final target = await _files.resolveFile(doc.localPath);
    if (await target.exists()) {
      onProgress?.call(1.0);
      return target;
    }
    await _repo.update(doc.copyWith(
      syncStatus: DocumentSyncStatus.missingLocal,
      updatedAt: DateTime.now(),
    ));
    return null;
  }

  /// Remove only the local binary (used on hard purge).
  ///
  /// Soft-delete / RTDB metadata removal is handled elsewhere; this method
  /// never touches the sync architecture.
  Future<void> deleteFromStorage(DocumentModel doc) async {
    try {
      final file = await _files.resolveFile(doc.localPath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[DocStorage] local delete failed (ignored): $e');
    }
  }

  /// Retry all pending/failed local saves (called on connectivity return).
  /// [onItem] lets the UI reflect per-document progress.
  Future<void> processQueue({
    void Function(DocumentModel doc, double progress)? onItem,
  }) async {
    final pending = await _repo.needingSync();
    for (final doc in pending) {
      if (!await _files.existsLocally(doc)) continue;
      try {
        await _repo.update(doc.copyWith(
          syncStatus: DocumentSyncStatus.uploading,
          updatedAt: DateTime.now(),
        ));
        await upload(doc, onProgress: (p) => onItem?.call(doc, p));
      } catch (e) {
        debugPrint('[DocStorage] save failed (queued): $e');
        await _repo.update(doc.copyWith(
          syncStatus: DocumentSyncStatus.failed,
          updatedAt: DateTime.now(),
        ));
      }
    }
  }
}

class DocumentStorageException implements Exception {
  const DocumentStorageException(this.message);
  final String message;
  @override
  String toString() => 'DocumentStorageException: $message';
}
