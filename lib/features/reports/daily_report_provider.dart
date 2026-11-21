import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/services/sync_service.dart';
import '../../sites/models/site_model.dart';

part 'daily_report_provider.generated.dart';

/// ChangeNotifier that manages daily report state with repository pattern.
/// Follows the same pattern as SiteProvider, WorkerProvider, etc.
class DailyReportProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  final FirebaseService _firebase;
  final SyncService _sync;
  final String _userId;

  /// List of daily reports, ordered by date descending
  final List<DailyReportModel> _reports = [];
  List<DailyReportModel> get reports => List.unmodifiable(_reports);

  /// Selected report for form editing
  DailyReportModel? _selectedReport;
  DailyReportModel? get selectedReport => _selectedReport;

  /// UUID generator for deterministic naming
  final _uuid = const Uuid();

  DailyReportProvider({
    required DatabaseHelper db,
    required FirebaseService firebase,
    required SyncService sync,
    required String userId,
  })  : _db = db,
        _firebase = firebase,
        _sync = sync,
        _userId = userId {
    _loadReports();
  }

  /// Load all daily reports from local SQLite, then sync with cloud
  Future<void> _loadReports() async {
    final List<Map<String, dynamic>> rows = await _db.query('daily_reports',
        orderBy: 'created_at DESC');
    _reports.clear();
    for (final row in rows) {
      _reports.add(DailyReportModel.fromMap(row));
    }
    notifyListeners();
  }

  /// Create a new daily report with photo attachments
  Future<DailyReportModel> createReport({
    required String title,
    required String date,
    required SiteModel site,
    required List<Uint8List> photos,
  }) async {
    final report = DailyReportModel(
      uuid: _uuid.v4(),
      userId: _userId,
      siteId: site.id,
      date: date,
      title: title,
      kind: 'text',
      contentRef: '',
      fileName: '$title_report.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 0,
      localPath: '',
      storagePath: '',
      hash: '',
      syncStatus: DailyReportSyncStatus.pending,
      isDeleted: false,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Save to local SQLite and get the auto-generated id
    final reportId = await _db.insert('daily_reports', report.toMap());

    // Save photos to local SQLite and upload to Firebase Storage
    final photoUris = <String>[];
    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final photoUuid = _uuid.v4();
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/daily_reports/${report.uuid}/photo_$photoUuid.jpg';
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(photo);

      final hash = sha256.convert(photo).toString();
      final photoModel = DailyReportPhotoModel(
        uuid: photoUuid,
        userId: _userId,
        dailyReportId: reportId,
        fileName: 'photo_$photoUuid.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: photo.lengthInBytes,
        localPath: filePath,
        hash: hash,
        syncStatus: DailyReportSyncStatus.pending,
        isDeleted: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _db.insert('daily_report_photos', photoModel.toMap());

      // Upload photo to Firebase Storage
      final storagePath = 'daily_reports/${report.uuid}/photos/$photoUuid.jpg';
      await _firebase.uploadFile(
        path: storagePath,
        bytes: photo,
        onMutate: (metadata) {
          photoModel = photoModel.copyWith(
            syncStatus: DailyReportSyncStatus.uploading,
            localPath: filePath,
          );
          _db.update('daily_report_photos', photoModel.toMap(),
              where: 'uuid = ?', whereArgs: [photoUuid]);
          _notifyUserMutated();
        },
      );

      photoUris.add(storagePath);
    }

    // Upload report PDF if applicable
    // ... (PDF generation logic)

    // Save report with photo references
    report.fileName = '$title_report.pdf';
    report.sizeBytes = 0; // calculated after PDF gen
    report.localPath = '';
    report.storagePath = '';
    report.hash = '';
    await _db.update('daily_reports', report.toMap(),
        where: 'uuid = ?', whereArgs: [report.uuid]);

    _reports.insert(0, report);
    notifyListeners();

    return report;
  }

  /// Update sync status for a report and propagate to cloud
  Future<void> syncReport(DailyReportModel report) async {
    report = report.copyWith(
      syncStatus: DailyReportSyncStatus.uploading,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _db.update('daily_reports', report.toMap(),
        where: 'uuid = ?', whereArgs: [report.uuid]);
    notifyListeners();

    // Firebase RTDB sync via onUserMutate hook
    await _sync.pushDailyReport(report);

    report = report.copyWith(
      syncStatus: DailyReportSyncStatus.synced,
    );
    await _db.update('daily_reports', report.toMap(),
        where: 'uuid = ?', whereArgs: [report.uuid]);
    notifyListeners();
  }

  /// Delete a report locally and mark for cloud sync
  Future<void> deleteReport(DailyReportModel report) async {
    report = report.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now().toIso8601String(),
      syncStatus: DailyReportSyncStatus.pending,
    );
    await _db.update('daily_reports', report.toMap(),
        where: 'uuid = ?', whereArgs: [report.uuid]);

    // Also delete associated photos
    final photos = await _db.query('daily_report_photos',
        where: 'daily_report_id = ?', whereArgs: [report.id]);
    for (final photo in photos) {
      final photoModel = DailyReportPhotoModel.fromMap(photo);
      await _db.delete('daily_report_photos',
          where: 'uuid = ?', whereArgs: [photo['uuid']]);
      // Delete from Firebase Storage
      await _firebase.deleteFile('daily_reports/${report.uuid}/photos/${photo['uuid']}');
    }

    await _db.delete('daily_reports', where: 'uuid = ?', whereArgs: [report.uuid]);
    _reports.remove(report);
    notifyListeners();

    await _sync.pushDailyReport(report);
  }

  /// Get a report by UUID
  DailyReportModel? getReportByUuid(String uuid) {
    return _reports.firstWhere((r) => r.uuid == uuid, orElse: () => null);
  }

  /// Refresh reports from SQLite (after external changes)
  Future<void> refresh() async {
    await _loadReports();
  }

  /// Notify Firebase that user data has mutated (for RTDB sync)
  void _notifyUserMutated() {
    _firebase.onUserMutate();
  }

  /// Export a specific report to PDF by UUID
  Future<Uint8List> exportReportPdf(String reportUuid) async {
    final report = getReportByUuid(reportUuid);
    if (report == null) throw ArgumentError('Report not found: $reportUuid');
    return await ReportExportService.exportReportPdf(
      report,
      getSiteName: _getSiteName,
      provider: this,
    );
  }

  String? _getSiteName(String siteId) async {
    final site = await _db.query(
      'sites',
      where: 'id = ?',
      whereArgs: [siteId],
    ).then((rows) => rows.isNotEmpty ? SiteModel.fromMap(rows.first) : null);
    return site?.name;
  }
}