/// Document Management — repository.
///
/// Thin facade over [DatabaseHelper] for the unified `documents` table,
/// matching the existing repository pattern (providers depend on this, never
/// on [DatabaseHelper] directly).
library;

import '../../../core/database/database_helper.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final _db = DatabaseHelper();

  Future<int> insert(DocumentModel doc) => _db.insertDocument(doc);

  Future<int> update(DocumentModel doc) => _db.updateDocument(doc);

  Future<int> softDelete(String uuid) => _db.softDeleteDocument(uuid);

  Future<int> restore(String uuid) => _db.restoreDocument(uuid);

  Future<int> hardDelete(String uuid) => _db.hardDeleteDocument(uuid);

  Future<DocumentModel?> byUuid(String uuid) => _db.getDocumentByUuid(uuid);

  Future<List<DocumentModel>> list({
    DocumentEntityType? entityType,
    int? entityId,
    bool includeDeleted = false,
  }) =>
      _db.getDocuments(
        entityType: entityType,
        entityId: entityId,
        includeDeleted: includeDeleted,
      );

  Future<List<DocumentModel>> search(String query) =>
      _db.searchDocuments(query);

  Future<List<DocumentModel>> needingSync() => _db.getDocumentsNeedingSync();
}