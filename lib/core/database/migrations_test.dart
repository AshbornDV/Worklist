import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:test/test.dart';
import '../database_helper.dart';
import '../models/daily_report_model.dart';
import '../models/shift_model.dart';
import '../models/leave_request_model.dart';

void main() {
  group('Database Migration Tests', () {
    late DatabaseHelper dbHelper;
    late Directory docsDir;

    setUpAll(async () async {
      docsDir = await getApplicationDocumentsDirectory();
      dbHelper = DatabaseHelper();
      await dbHelper.initialize();
    });

    tearDownAll(async () async {
      await dbHelper.close();
    });

    test('v21 migration: creates daily_reports table', () async {
      // Open a fresh DB with v20 schema (before migration)
      final freshDb = await openDatabase(
        join(docsDir.path, 'test_daily_reports.db'),
        schemaVersion: 20,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE daily_reports (
            uuid TEXT PRIMARY KEY,
            userId INTEGER NOT NULL,
            siteId INTEGER,
            date TEXT NOT NULL,
            title TEXT,
            kind TEXT,
            contentRef TEXT,
            fileName TEXT,
            mimeType TEXT,
            sizeBytes INTEGER,
            localPath TEXT,
            storagePath TEXT,
            hash TEXT,
            thumbPath TEXT,
            syncStatus TEXT DEFAULT 'local',
            isDeleted INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          );
        '''),
      );

      // Run migration to v21
      await dbHelper.runMigration(freshDb, 20, 21);

      // Verify daily_reports table exists with expected columns
      final tableInfo = await freshDb.execute('PRAGMA table_info(daily_reports)');
      final columnNames = (tableInfo as List).map((row) => row['name'] as String).toList();

      expect(columnNames).toContain('uuid');
      expect(columnNames).toContain('userId');
      expect(columnNames).toContain('siteId');
      expect(columnNames).toContain('date');
      expect(columnNames).toContain('title');
      expect(columnNames).toContain('kind');
      expect(columnNames).toContain('contentRef');
      expect(columnNames).toContain('fileName');
      expect(columnNames).toContain('mimeType');
      expect(columnNames).toContain('sizeBytes');
      expect(columnNames).toContain('localPath');
      expect(columnNames).toContain('storagePath');
      expect(columnNames).toContain('hash');
      expect(columnNames).toContain('thumbPath');
      expect(columnNames).toContain('syncStatus');
      expect(columnNames).toContain('isDeleted');
      expect(columnNames).toContain('createdAt');
      expect(columnNames).toContain('updatedAt');

      await closeDatabase(freshDb);
    });

    test('v22 migration: creates daily_report_photos table', () async {
      final freshDb = await openDatabase(
        join(docsDir.path, 'test_daily_report_photos.db'),
        schemaVersion: 21,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE daily_reports (
            uuid TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            siteId TEXT,
            date TEXT NOT NULL,
            title TEXT,
            kind TEXT,
            contentRef TEXT,
            syncStatus TEXT DEFAULT 'local',
            isDeleted INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          );
        '''),
      );

      // Run migration to v22
      await dbHelper.runMigration(freshDb, 21, 22);

      // Verify daily_report_photos table exists
      final tableInfo = await freshDb.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='daily_report_photos'");
      expect(tableInfo).isNotEmpty;

      // Verify columns
      final photoTableInfo = await freshDb.execute('PRAGMA table_info(daily_report_photos)');
      final photoColumns = (photoTableInfo as List).map((row) => row['name'] as String).toList();

      expect(photoColumns).toContain('uuid');
      expect(photoColumns).toContain('fileName');
      expect(photoColumns).toContain('mimeType');
      expect(photoColumns).toContain('sizeBytes');
      expect(photoColumns).toContain('localPath');
      expect(photoColumns).toContain('storagePath');
      expect(photoColumns).toContain('hash');
      expect(photoColumns).toContain('thumbPath');
      expect(photoColumns).toContain('createdAt');
      expect(photoColumns).toContain('updatedAt');

      await closeDatabase(freshDb);
    });

    test('v23 migration: creates shifts table', () async {
      final freshDb = await openDatabase(
        join(docsDir.path, 'test_shifts.db'),
        schemaVersion: 22,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE daily_reports (
            uuid TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            siteId TEXT,
            date TEXT NOT NULL,
            title TEXT,
            kind TEXT,
            contentRef TEXT,
            syncStatus TEXT DEFAULT 'local',
            isDeleted INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          );
        '''),
      );

      // Run migration to v23
      await dbHelper.runMigration(freshDb, 22, 23);

      // Verify shifts table exists
      final tableInfo = await freshDb.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='shifts'");
      expect(tableInfo).isNotEmpty;

      // Verify columns
      final shiftTableInfo = await freshDb.execute('PRAGMA table_info(shifts)');
      final shiftColumns = (shiftTableInfo as List).map((row) => row['name'] as String).toList();

      expect(shiftColumns).toContain('uuid');
      expect(shiftColumns).toContain('userId');
      expect(shiftColumns).toContain('siteId');
      expect(shiftColumns).toContain('date');
      expect(shiftColumns).toContain('startTime');
      expect(shiftColumns).toContain('endTime');
      expect(shiftColumns).toContain('kind');
      expect(shiftColumns).toContain('status');
      expect(shiftColumns).toContain('localPath');
      expect(shiftColumns).toContain('storagePath');
      expect(shiftColumns).toContain('hash');
      expect(shiftColumns).toContain('createdAt');
      expect(shiftColumns).toContain('updatedAt');

      await closeDatabase(freshDb);
    });

    test('v24 migration: creates leave_requests table', () async {
      final freshDb = await openDatabase(
        join(docsDir.path, 'test_leave.db'),
        schemaVersion: 23,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE shifts (
            uuid TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            siteId TEXT,
            date TEXT NOT NULL,
            startTime TEXT NOT NULL,
            endTime TEXT NOT NULL,
            kind TEXT,
            status TEXT DEFAULT 'local',
            localPath TEXT,
            storagePath TEXT,
            hash TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          );
        '''),
      );

      // Run migration to v24
      await dbHelper.runMigration(freshDb, 23, 24);

      // Verify leave_requests table exists
      final tableInfo = await freshDb.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='leave_requests'");
      expect(tableInfo).isNotEmpty;

      // Verify columns
      final leaveTableInfo = await freshDb.execute('PRAGMA table_info(leave_requests)');
      final leaveColumns = (leaveTableInfo as List).map((row) => row['name'] as String).toList();

      expect(leaveColumns).toContain('uuid');
      expect(leaveColumns).toContain('userId');
      expect(leaveColumns).toContain('siteId');
      expect(leaveColumns).toContain('date');
      expect(leaveColumns).toContain('type');
      expect(leaveColumns).toContain('reason');
      expect(leaveColumns).toContain('duration');
      expect(leaveColumns).toContain('status');
      expect(leaveColumns).toContain('localPath');
      expect(leaveColumns).toContain('storagePath');
      expect(leaveColumns).toContain('hash');
      expect(leaveColumns).toContain('createdAt');
      expect(leaveColumns).toContain('updatedAt');

      await closeDatabase(freshDb);
    });

    test('v21→v22→v23→v24 migrations are idempotent', () async {
      // Run all migrations sequentially on a fresh DB
      final freshDb = await openDatabase(
        join(docsDir.path, 'test_idempotent.db'),
        schemaVersion: 20,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE daily_reports (
            uuid TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            siteId TEXT,
            date TEXT NOT NULL,
            title TEXT,
            kind TEXT,
            contentRef TEXT,
            syncStatus TEXT DEFAULT 'local',
            isDeleted INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          );
        '''),
      );

      // Run all migrations
      await dbHelper.runMigration(freshDb, 20, 21);
      await dbHelper.runMigration(freshDb, 21, 22);
      await dbHelper.runMigration(freshDb, 22, 23);
      await dbHelper.runMigration(freshDb, 23, 24);

      // Verify all tables exist
      final tables = await freshDb.execute("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = (tables as List).map((row) => row['name'] as String).toList();

      expect(tableNames).toContain('daily_reports');
      expect(tableNames).toContain('daily_report_photos');
      expect(tableNames).toContain('shifts');
      expect(tableNames).toContain('leave_requests');

      await closeDatabase(freshDb);
    });

    test('migrations use IF NOT EXISTS for idempotent upgrades', () async {
      final freshDb = await openDatabase(
        join(docsDir.path, 'test_if_not_exists.db'),
        schemaVersion: 20,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE daily_reports (
            uuid TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            siteId TEXT,
            date TEXT NOT NULL,
            title TEXT,
            kind TEXT,
            contentRef TEXT,
            syncStatus TEXT DEFAULT 'local',
            isDeleted INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          );
        '''),
      );

      // Run migrations multiple times
      await dbHelper.runMigration(freshDb, 20, 21);
      await dbHelper.runMigration(freshDb, 21, 22);
      await dbHelper.runMigration(freshDb, 22, 23);
      await dbHelper.runMigration(freshDb, 23, 24);
      await dbHelper.runMigration(freshDb, 20, 21); // Re-run v21
      await dbHelper.runMigration(freshDb, 21, 22); // Re-run v22
      await dbHelper.runMigration(freshDb, 22, 23); // Re-run v23
      await dbHelper.runMigration(freshDb, 23, 24); // Re-run v24

      // Verify data integrity - all tables still exist and are not corrupted
      final tables = await freshDb.execute("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = (tables as List).map((row) => row['name'] as String).toList();

      expect(tableNames).toContain('daily_reports');
      expect(tableNames).toContain('daily_report_photos');
      expect(tableNames).toContain('shifts');
      expect(tableNames).toContain('leave_requests');

      // Verify each table has data
      for (final table in ['daily_reports', 'daily_report_photos', 'shifts', 'leave_requests']) {
        final count = await freshDb.execute('SELECT COUNT(*) FROM $table');
        expect(count).toNotEqual(0);
      }

      await closeDatabase(freshDb);
    });
  });
}