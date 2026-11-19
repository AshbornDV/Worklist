import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../models/construction_payment_model.dart';
import '../models/advance_payment_model.dart';
import '../models/attendance_model.dart';
import '../../features/documents/models/document_model.dart';
import '../models/product_model.dart';
import '../models/site_model.dart';
import '../models/site_product_model.dart';
import '../models/site_service_model.dart';
import '../models/store_product_model.dart';
import '../models/user_model.dart';
import '../models/user_service_model.dart';
import '../models/payroll_model.dart';
import '../models/worker_document_model.dart';
import '../models/worker_model.dart';
import '../models/worker_performance_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;
  static Future<Database>? _dbInit;
  int? _activeUserId;

  int? get activeUserId => _activeUserId;

  /// Public, throwing variant of [_requireUserId] for callers outside the DB
  /// layer (e.g. the Documents provider) that need the signed-in user id.
  int requireUserId() => _requireUserId();

  /// Test seam: executes a SQL script whose statements are separated by `;`.
  /// Characterization tests use it to seed data with SQL that the Kotlin port
  /// replays verbatim, so the fixture never depends on Dart-only code paths.
  Future<void> runRawSqlScript(String script) async {
    final db = await database;
    for (final statement in script.split(';')) {
      if (statement.trim().isEmpty) continue;
      await db.execute(statement);
    }
  }

  /// Test seam: runs an arbitrary read query through the open connection.
  Future<List<Map<String, Object?>>> rawQuery(String sql) async {
    final db = await database;
    return db.rawQuery(sql);
  }

  // ── Cloud-sync write hook ────────────────────────────────────────────────
  // Fired after any local user-data mutation so the cloud-sync layer can push
  // the change. Implemented as a callback (not a direct Firebase import) to
  // respect the architecture rule that the database layer must not depend on
  // Firebase. Wired up in main() once Firebase is initialized.
  static void Function()? onUserMutate;

  // Suppressed while importing cloud data (replaceUserData) so the import
  // itself doesn't trigger a re-upload loop.
  bool _suppressMutateNotify = false;

  void _notifyUserMutated() {
    if (_suppressMutateNotify) return;
    onUserMutate?.call();
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _dbInit ??= _initDatabase().then((db) {
      _db = db;
      return db;
    });
    return _dbInit!;
  }

  void setActiveUser(UserModel? user) {
    _activeUserId = user?.id;
  }

  int _requireUserId() {
    final userId = _activeUserId;
    if (userId == null) {
      throw StateError('Please sign in before accessing Worklist data.');
    }
    return userId;
  }

  Future<Database> _initDatabase() async {
    final dbPath = p.join(await getDatabasesPath(), 'worklist.db');
    return openDatabase(
      dbPath,
      version: 20,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createBusinessTables(db);
    await _createDocumentsTable(db);
    await _createIndexes(db);
  }

  /// Phase 8 — Document Management. Unified `documents` table covering all six
  /// entity types (worker/site/product/payroll/payment/service) via
  /// (entity_type, entity_id). Pure additive schema, idempotent (IF NOT EXISTS),
  /// so it is safe to run from both [_onCreate] and [onUpgrade].
  Future<void> _createDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        user_id INTEGER NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        category TEXT,
        file_name TEXT NOT NULL,
        mime_type TEXT,
        ext TEXT,
        size_bytes INTEGER NOT NULL,
        local_path TEXT NOT NULL,
        storage_path TEXT,
        thumb_path TEXT,
        hash TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        replaces_uuid TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        width INTEGER,
        height INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_documents_entity ON documents(user_id, entity_type, entity_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_documents_uuid ON documents(uuid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_documents_sync ON documents(user_id, sync_status)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _dropBusinessTables(db);
      await db.delete('users', where: 'username = ?', whereArgs: ['admin']);
      await _createBusinessTables(db);
    }
    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'sites', 'work_type', 'TEXT');
      await _addColumnIfMissing(db, 'sites', 'work_area', 'TEXT');
      await _addColumnIfMissing(db, 'sites', 'rate', 'REAL DEFAULT 0.0');
      await _addColumnIfMissing(db, 'sites', 'last_paid_date', 'TEXT');
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(db, 'sites', 'google_maps_url', 'TEXT');
      await _addColumnIfMissing(db, 'sites', 'latitude', 'REAL');
      await _addColumnIfMissing(db, 'sites', 'longitude', 'REAL');
    }
    if (oldVersion < 5) {
      await _createIndexes(db);
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        'sites',
        'site_size',
        "TEXT DEFAULT '${AppConstants.siteSizeSmall}'",
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS site_construction_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          site_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          payment_date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_site_payments_site ON site_construction_payments(user_id, site_id, payment_date)',
      );
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(
        db,
        'sites',
        'construction_paid',
        'REAL DEFAULT 0.0',
      );
    }
    if (oldVersion < 8) {
      await _createIndexes(db);
      await db.execute('''
        CREATE TABLE IF NOT EXISTS site_construction_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          site_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          payment_date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_site_payments_site ON site_construction_payments(user_id, site_id, payment_date)',
      );
      for (final col in [
        ('work_type', 'TEXT'),
        ('work_area', 'TEXT'),
        ('rate', 'REAL DEFAULT 0.0'),
        ('last_paid_date', 'TEXT'),
        ('google_maps_url', 'TEXT'),
        ('latitude', 'REAL'),
        ('longitude', 'REAL'),
        ('site_size', "TEXT DEFAULT '${AppConstants.siteSizeSmall}'"),
        ('construction_paid', 'REAL DEFAULT 0.0'),
      ]) {
        await _addColumnIfMissing(db, 'sites', col.$1, col.$2);
      }
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS store_products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          rate REAL NOT NULL DEFAULT 0.0,
          stock REAL NOT NULL DEFAULT 0.0,
          unit TEXT NOT NULL DEFAULT 'unit',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS site_products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          site_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          quantity REAL NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES store_products (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS site_services (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          site_id INTEGER NOT NULL,
          service_name TEXT NOT NULL,
          rate REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_store_products_user ON store_products(user_id, name)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_site_products_site ON site_products(user_id, site_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_site_services_site ON site_services(user_id, site_id)',
      );
    }
    if (oldVersion < 10) {
      // Add size column to store_products
      await _addColumnIfMissing(
          db, 'store_products', 'size', 'REAL NOT NULL DEFAULT 1.0');
      // Remove duplicates before adding unique index
      await db.execute('''
        DELETE FROM store_products WHERE id NOT IN (
          SELECT MIN(id) FROM store_products GROUP BY user_id, name
        )
      ''');
      // Replace old index with unique constraint index
      await db.execute('DROP INDEX IF EXISTS idx_store_products_user');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_store_products_unique ON store_products(user_id, name)',
      );
      // Add work_area_unit to sites
      await _addColumnIfMissing(db, 'sites', 'work_area_unit', 'TEXT');
      // Create user_services table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_services (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          rate REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_services_user ON user_services(user_id, name)',
      );
    }
    if (oldVersion < 11) {
      await _addColumnIfMissing(db, 'sites', 'final_cost', 'REAL');
      await _addColumnIfMissing(db, 'sites', 'work_type_rate', 'REAL');
    }
    if (oldVersion < 12) {
      // Add new worker profile fields
      await _addColumnIfMissing(db, 'workers', 'photo_path', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'address', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'skills', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'join_date', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'notes', 'TEXT');

      // Create worker_documents table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS worker_documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          worker_id INTEGER NOT NULL,
          document_type TEXT NOT NULL,
          file_path TEXT NOT NULL,
          uploaded_at TEXT NOT NULL,
          file_name TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_worker_documents_worker ON worker_documents(user_id, worker_id)',
      );

      // Create worker_performance table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS worker_performance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          worker_id INTEGER NOT NULL,
          month TEXT NOT NULL,
          attendance_percentage REAL NOT NULL DEFAULT 0.0,
          late_arrivals INTEGER NOT NULL DEFAULT 0,
          completed_work_days INTEGER NOT NULL DEFAULT 0,
          rating REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
          UNIQUE (user_id, worker_id, month)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_worker_performance_worker ON worker_performance(user_id, worker_id, month)',
      );
    }
    if (oldVersion < 13) {
      // Add new site detail fields
      await _addColumnIfMissing(db, 'sites', 'budget', 'REAL');
      await _addColumnIfMissing(db, 'sites', 'manager', 'TEXT');
      await _addColumnIfMissing(db, 'sites', 'start_date', 'TEXT');
      await _addColumnIfMissing(db, 'sites', 'end_date', 'TEXT');
    }
    if (oldVersion < 14) {
      // Product categories + barcode + stock thresholds.
      await _addColumnIfMissing(db, 'store_products', 'category', 'TEXT');
      await _addColumnIfMissing(db, 'store_products', 'subcategory', 'TEXT');
      await _addColumnIfMissing(db, 'store_products', 'color_label', 'TEXT');
      await _addColumnIfMissing(db, 'store_products', 'barcode', 'TEXT');
      await _addColumnIfMissing(
        db,
        'store_products',
        'low_stock_threshold',
        'REAL NOT NULL DEFAULT 10.0',
      );
      await _addColumnIfMissing(
        db,
        'store_products',
        'critical_stock_threshold',
        'REAL NOT NULL DEFAULT 2.0',
      );

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_store_products_barcode ON store_products(user_id, barcode)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_store_products_category ON store_products(user_id, category, subcategory)',
      );
    }
    if (oldVersion < 15) {
      // Add overtime_rate to workers
      await _addColumnIfMissing(
          db, 'workers', 'overtime_rate', 'REAL NOT NULL DEFAULT 0.0');
      // Create payroll table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payroll (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          worker_id INTEGER NOT NULL,
          month TEXT NOT NULL,
          full_days INTEGER NOT NULL DEFAULT 0,
          half_days INTEGER NOT NULL DEFAULT 0,
          daily_rate REAL NOT NULL DEFAULT 0.0,
          overtime_hours REAL NOT NULL DEFAULT 0.0,
          overtime_rate REAL NOT NULL DEFAULT 0.0,
          advance_amount REAL NOT NULL DEFAULT 0.0,
          bonus REAL NOT NULL DEFAULT 0.0,
          deductions REAL NOT NULL DEFAULT 0.0,
          net_salary REAL NOT NULL DEFAULT 0.0,
          status TEXT NOT NULL DEFAULT 'draft',
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
          UNIQUE (user_id, worker_id, month)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payroll_worker ON payroll(user_id, worker_id, month)',
      );
    }
    if (oldVersion < 16) {
      // Heal databases created by onCreate before these site columns were
      // added to the CREATE TABLE statement (previously only added via the
      // v10/v11 upgrade paths, which fresh installs at v15 never ran).
      await _addColumnIfMissing(db, 'sites', 'work_area_unit', 'TEXT');
      await _addColumnIfMissing(db, 'sites', 'work_type_rate', 'REAL');
      await _addColumnIfMissing(db, 'sites', 'final_cost', 'REAL');
    }
    if (oldVersion < 17) {
      // Heal databases created by an earlier v16 build whose onCreate path
      // did not yet include worker_documents / worker_performance / payroll.
      // Such databases already sit at version 16, so onUpgrade never ran again
      // and these tables were never created — causing "no such table" at
      // runtime. CREATE TABLE IF NOT EXISTS is idempotent and safe on live
      // user databases: it only adds missing tables, never drops or alters
      // existing data.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS worker_documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          worker_id INTEGER NOT NULL,
          document_type TEXT NOT NULL,
          file_path TEXT NOT NULL,
          uploaded_at TEXT NOT NULL,
          file_name TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_worker_documents_worker ON worker_documents(user_id, worker_id)',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS worker_performance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          worker_id INTEGER NOT NULL,
          month TEXT NOT NULL,
          attendance_percentage REAL NOT NULL DEFAULT 0.0,
          late_arrivals INTEGER NOT NULL DEFAULT 0,
          completed_work_days INTEGER NOT NULL DEFAULT 0,
          rating REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
          UNIQUE (user_id, worker_id, month)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_worker_performance_worker ON worker_performance(user_id, worker_id, month)',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payroll (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          worker_id INTEGER NOT NULL,
          month TEXT NOT NULL,
          full_days INTEGER NOT NULL DEFAULT 0,
          half_days INTEGER NOT NULL DEFAULT 0,
          daily_rate REAL NOT NULL DEFAULT 0.0,
          overtime_hours REAL NOT NULL DEFAULT 0.0,
          overtime_rate REAL NOT NULL DEFAULT 0.0,
          advance_amount REAL NOT NULL DEFAULT 0.0,
          bonus REAL NOT NULL DEFAULT 0.0,
          deductions REAL NOT NULL DEFAULT 0.0,
          net_salary REAL NOT NULL DEFAULT 0.0,
          status TEXT NOT NULL DEFAULT 'draft',
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
          UNIQUE (user_id, worker_id, month)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payroll_worker ON payroll(user_id, worker_id, month)',
      );
    }
    if (oldVersion < 18) {
      // Heal databases created at v17 (or earlier) whose onCreate path never
      // added the worker profile columns (photo_path, address, skills,
      // join_date, notes). Fresh installs at v17 hit this gap and INSERTs
      // referencing those columns failed with "no such column". The upgrade
      // path added them, but only for DBs that upgraded from <12 — a v17 DB
      // created directly skipped that branch. ALTER ... ADD COLUMN is
      // idempotent via _addColumnIfMissing, so re-running on an already-healed
      // DB is a safe no-op.
      await _addColumnIfMissing(db, 'workers', 'photo_path', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'address', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'skills', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'join_date', 'TEXT');
      await _addColumnIfMissing(db, 'workers', 'notes', 'TEXT');
    }
    if (oldVersion < 19) {
      // Phase 8 — Document Management (see [_createDocumentsTable] for DDL).
      // Additive only: CREATE TABLE / INDEX IF NOT EXISTS. Delegated to the
      // shared helper so fresh installs and upgrades stay identical.
      await _createDocumentsTable(db);
    }
    if (oldVersion < 20) {
      // Phase 14 — Windows cloud-restore fix. Fresh installs (created at v19
      // via [_onCreate]) had the `documents` table via the helper above, but
      // some v19 databases created before the helper existed can be missing it
      // when a cloud "Restore from cloud" runs replaceUserData (which queries
      // `documents`). Re-create it idempotently so the download never throws
      // `no such table: documents`. Pure additive migration.
      await _createDocumentsTable(db);
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final existing = await db.rawQuery('PRAGMA table_info($table)');
    final hasColumn = existing.any((row) => row['name'] == column);
    if (!hasColumn) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT DEFAULT 'manager',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _dropBusinessTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS site_services');
    await db.execute('DROP TABLE IF EXISTS site_products');
    await db.execute('DROP TABLE IF EXISTS user_services');
    await db.execute('DROP TABLE IF EXISTS store_products');
    await db.execute('DROP TABLE IF EXISTS site_construction_payments');
    await db.execute('DROP TABLE IF EXISTS advance_payments');
    await db.execute('DROP TABLE IF EXISTS attendance');
    await db.execute('DROP TABLE IF EXISTS site_workers');
    await db.execute('DROP TABLE IF EXISTS products');
    await db.execute('DROP TABLE IF EXISTS workers');
    await db.execute('DROP TABLE IF EXISTS sites');
  }

  Future<void> _createBusinessTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        area TEXT NOT NULL,
        google_maps_url TEXT,
        latitude REAL,
        longitude REAL,
        work_type TEXT,
        work_area TEXT,
        work_area_unit TEXT,
        work_type_rate REAL,
        final_cost REAL,
        rate REAL DEFAULT 0.0,
        status TEXT DEFAULT 'active',
        estimated_cost REAL DEFAULT 0.0,
        advance_received REAL DEFAULT 0.0,
        construction_paid REAL DEFAULT 0.0,
        site_size TEXT DEFAULT '${AppConstants.siteSizeSmall}',
        last_paid_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT DEFAULT '',
        trade TEXT NOT NULL,
        daily_rate REAL NOT NULL,
        overtime_rate REAL NOT NULL DEFAULT 0.0,
        status TEXT DEFAULT 'active',
        photo_path TEXT,
        address TEXT,
        skills TEXT,
        join_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        site_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        delivery_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS site_workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        site_id INTEGER NOT NULL,
        worker_id INTEGER NOT NULL,
        assigned_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
        UNIQUE (user_id, site_id, worker_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        worker_id INTEGER NOT NULL,
        site_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE,
        UNIQUE (user_id, worker_id, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS advance_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        worker_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        request_date TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        approved_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS site_construction_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        site_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        subcategory TEXT,
        color_label TEXT,
        barcode TEXT,
        rate REAL NOT NULL DEFAULT 0.0,
        size REAL NOT NULL DEFAULT 1.0,
        unit TEXT NOT NULL DEFAULT 'piece',
        stock REAL NOT NULL DEFAULT 0.0,
        low_stock_threshold REAL NOT NULL DEFAULT 10.0,
        critical_stock_threshold REAL NOT NULL DEFAULT 2.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE (user_id, name)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS site_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        site_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES store_products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS site_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        site_id INTEGER NOT NULL,
        service_name TEXT NOT NULL,
        rate REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        rate REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS worker_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        worker_id INTEGER NOT NULL,
        document_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        uploaded_at TEXT NOT NULL,
        file_name TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_worker_documents_worker ON worker_documents(user_id, worker_id)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS worker_performance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        worker_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        attendance_percentage REAL NOT NULL DEFAULT 0.0,
        late_arrivals INTEGER NOT NULL DEFAULT 0,
        completed_work_days INTEGER NOT NULL DEFAULT 0,
        rating REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
        UNIQUE (user_id, worker_id, month)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_worker_performance_worker ON worker_performance(user_id, worker_id, month)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payroll (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        worker_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        full_days INTEGER NOT NULL DEFAULT 0,
        half_days INTEGER NOT NULL DEFAULT 0,
        daily_rate REAL NOT NULL DEFAULT 0.0,
        overtime_hours REAL NOT NULL DEFAULT 0.0,
        overtime_rate REAL NOT NULL DEFAULT 0.0,
        advance_amount REAL NOT NULL DEFAULT 0.0,
        bonus REAL NOT NULL DEFAULT 0.0,
        deductions REAL NOT NULL DEFAULT 0.0,
        net_salary REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'draft',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
        UNIQUE (user_id, worker_id, month)
      )
    ''');
  }

  /// Creates performance indexes for all high-frequency query patterns.
  /// Uses IF NOT EXISTS so it is safe to call on both fresh installs and upgrades.
  Future<void> _createIndexes(Database db) async {
    // sites: getAllSites filters by user_id, orders by created_at
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sites_user_created ON sites(user_id, created_at)');
    // workers: getAllWorkers filters by user_id, orders by name
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_workers_user_name ON workers(user_id, name)');
    // products: getProductsBySite filters by user_id + site_id, orders by delivery_date
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_site ON products(user_id, site_id, delivery_date)');
    // site_workers: JOIN from sites→workers and workers→sites
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sw_site ON site_workers(user_id, site_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sw_worker ON site_workers(user_id, worker_id)');
    // attendance: lookup by worker+date and by site+date
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_att_worker_date ON attendance(user_id, worker_id, date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_att_site_date ON attendance(user_id, site_id, date)');
    // advance_payments: pending list and monthly approved totals
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_adv_user_status ON advance_payments(user_id, status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_adv_worker ON advance_payments(user_id, worker_id, approved_date)');
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_store_products_unique ON store_products(user_id, name)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_store_products_barcode ON store_products(user_id, barcode)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_store_products_category ON store_products(user_id, category, subcategory)',
    );
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_site_products_site ON site_products(user_id, site_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_site_services_site ON site_services(user_id, site_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_services_user ON user_services(user_id, name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payroll_worker ON payroll(user_id, worker_id, month)');
  }

  String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Map<String, dynamic> _owned(Map<String, dynamic> map, int userId) {
    final next = Map<String, dynamic>.from(map);
    next['user_id'] = userId;
    return next;
  }

  Map<String, dynamic> _insertable(
    Map<String, dynamic> map,
    int userId, {
    Map<int, int>? siteIds,
    Map<int, int>? workerIds,
  }) {
    final next = Map<String, dynamic>.from(map);
    next.remove('id');
    next['user_id'] = userId;
    if (siteIds != null && next['site_id'] != null) {
      next['site_id'] = siteIds[(next['site_id'] as num).toInt()];
    }
    if (workerIds != null && next['worker_id'] != null) {
      next['worker_id'] = workerIds[(next['worker_id'] as num).toInt()];
    }
    return next;
  }

  Future<UserModel?> authenticate(String username, String password) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'LOWER(username) = ? AND password_hash = ?',
      whereArgs: [username.trim().toLowerCase(), hashPassword(password)],
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<UserModel> createAccount(String username, String password) async {
    final db = await database;
    final cleanedUsername = username.trim();
    if (cleanedUsername.length < 3) {
      throw Exception('Username must be at least 3 characters.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    final existing = await getUserByUsername(cleanedUsername);
    if (existing != null) {
      throw Exception('That username is already registered.');
    }

    final now = DateTime.now();
    final id = await db.insert('users', {
      'username': cleanedUsername,
      'password_hash': hashPassword(password),
      'role': 'manager',
      'created_at': now.toIso8601String(),
    });
    return UserModel(
      id: id,
      username: cleanedUsername,
      passwordHash: hashPassword(password),
      role: 'manager',
      createdAt: now,
    );
  }

  Future<int> createUser(UserModel user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  Future<UserModel> ensureGoogleLocalAccount(String username) async {
    final cleanedUsername = username.trim();
    if (cleanedUsername.length < 3) {
      throw Exception('Google account username is too short.');
    }
    final existing = await getUserByUsername(cleanedUsername);
    if (existing != null) return existing;
    return createAccount(cleanedUsername, _randomPassword());
  }

  String _randomPassword() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<UserModel> ensureLocalAccount(String username, String password) async {
    final db = await database;
    final cleanedUsername = username.trim();
    final existing = await getUserByUsername(cleanedUsername);
    final passwordHash = hashPassword(password);
    if (existing != null) {
      await db.update(
        'users',
        {'password_hash': passwordHash},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return UserModel(
        id: existing.id,
        username: existing.username,
        passwordHash: passwordHash,
        role: existing.role,
        createdAt: existing.createdAt,
      );
    }

    return createAccount(cleanedUsername, password);
  }

  Future<List<SiteModel>> getAllSites() async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'sites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(SiteModel.fromMap).toList();
  }

  Future<SiteModel?> getSiteById(int id) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'sites',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return rows.isEmpty ? null : SiteModel.fromMap(rows.first);
  }

  Future<int> insertSite(SiteModel site) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.insert('sites', _owned(site.toMap(), userId));
  }

  Future<int> updateSite(SiteModel site) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.update(
      'sites',
      _owned(site.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [site.id, userId],
    );
  }

  Future<int> deleteSite(int id) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.delete(
      'sites',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<ProductModel>> getProductsBySite(int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'products',
      where: 'site_id = ? AND user_id = ?',
      whereArgs: [siteId, userId],
      orderBy: 'delivery_date DESC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  /// Read-only: all products across the current user's sites. Used by the
  /// Calendar to surface material delivery reminders. No schema change.
  Future<List<ProductModel>> getAllProducts() async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'products',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'delivery_date DESC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert('products', _owned(product.toMap(), userId));
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    final userId = _requireUserId();
    return db.update(
      'products',
      _owned(product.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [product.id, userId],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.delete(
      'products',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ─────────────── STORE PRODUCTS (global inventory) ───────────────

  Future<List<StoreProduct>> getAllStoreProducts() async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'store_products',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return rows.map(StoreProduct.fromMap).toList();
  }

  Future<StoreProduct?> getStoreProductById(int id) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'store_products',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return rows.isEmpty ? null : StoreProduct.fromMap(rows.first);
  }

  Future<StoreProduct?> getStoreProductByBarcode(String barcode) async {
    final db = await database;
    final userId = _requireUserId();
    final cleaned = barcode.trim();
    if (cleaned.isEmpty) return null;
    final rows = await db.query(
      'store_products',
      where: 'barcode = ? AND user_id = ?',
      whereArgs: [cleaned, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : StoreProduct.fromMap(rows.first);
  }

  Future<int> insertStoreProduct(StoreProduct product) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert('store_products', _owned(product.toMap(), userId));
  }

  Future<int> updateStoreProduct(StoreProduct product) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.update(
      'store_products',
      _owned(product.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [product.id, userId],
    );
  }

  Future<int> deleteStoreProduct(int id) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'store_products',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Deducts [quantity] from the store product's stock.
  /// Throws if the stock would go negative.
  Future<void> deductStoreStock(int productId, double quantity) async {
    final db = await database;
    final userId = _requireUserId();
    final affected = await db.rawUpdate('''
      UPDATE store_products
      SET stock = stock - ?, updated_at = ?
      WHERE id = ? AND user_id = ? AND stock >= ?
    ''', [
      quantity,
      DateTime.now().toIso8601String(),
      productId,
      userId,
      quantity
    ]);
    if (affected == 0) {
      throw Exception('Insufficient stock or product not found.');
    }
  }

  /// Restores [quantity] back to the store product's stock.
  Future<void> restoreStoreStock(int productId, double quantity) async {
    final db = await database;
    final userId = _requireUserId();
    await db.rawUpdate('''
      UPDATE store_products
      SET stock = stock + ?, updated_at = ?
      WHERE id = ? AND user_id = ?
    ''', [quantity, DateTime.now().toIso8601String(), productId, userId]);
  }

  // ─────────────── SITE PRODUCTS (products sent to a site) ───────────────

  Future<List<SiteProduct>> getSiteProducts(int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.rawQuery('''
      SELECT sp.*, p.name AS product_name, p.rate AS product_rate, p.unit AS product_unit
      FROM site_products sp
      INNER JOIN store_products p ON sp.product_id = p.id AND p.user_id = sp.user_id
      WHERE sp.site_id = ? AND sp.user_id = ?
      ORDER BY sp.created_at DESC
    ''', [siteId, userId]);
    return rows.map(SiteProduct.fromMap).toList();
  }

  /// Sends a product from store inventory to a site in one transaction.
  /// Deducts store stock and creates a site_product record.
  Future<SiteProduct> sendProductToSite(
      int siteId, int productId, double quantity) async {
    final db = await database;
    final userId = _requireUserId();

    return await db.transaction((txn) async {
      final affected = await txn.rawUpdate('''
        UPDATE store_products
        SET stock = stock - ?, updated_at = ?
        WHERE id = ? AND user_id = ? AND stock >= ?
      ''', [
        quantity,
        DateTime.now().toIso8601String(),
        productId,
        userId,
        quantity
      ]);
      if (affected == 0) {
        throw Exception(
            'Insufficient stock. Cannot send more than available inventory.');
      }

      final now = DateTime.now();
      final id = await txn.insert('site_products', {
        'user_id': userId,
        'site_id': siteId,
        'product_id': productId,
        'quantity': quantity,
        'created_at': now.toIso8601String(),
      });

      return SiteProduct(
        id: id,
        siteId: siteId,
        productId: productId,
        quantity: quantity,
        createdAt: now,
      );
    });
  }

  Future<int> deleteSiteProduct(int id) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.delete(
      'site_products',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ─────────────── SITE SERVICES ───────────────

  Future<List<SiteService>> getSiteServices(int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'site_services',
      where: 'site_id = ? AND user_id = ?',
      whereArgs: [siteId, userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(SiteService.fromMap).toList();
  }

  Future<int> insertSiteService(SiteService service) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert('site_services', _owned(service.toMap(), userId));
  }

  Future<int> updateSiteService(SiteService service) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.update(
      'site_services',
      _owned(service.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [service.id, userId],
    );
  }

  Future<int> deleteSiteService(int id) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'site_services',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ─────────────── USER SERVICES (global service catalog) ───────────────

  Future<List<UserService>> getAllUserServices() async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'user_services',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return rows.map(UserService.fromMap).toList();
  }

  Future<UserService?> getUserServiceById(int id) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'user_services',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return rows.isEmpty ? null : UserService.fromMap(rows.first);
  }

  Future<int> insertUserService(UserService service) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert('user_services', _owned(service.toMap(), userId));
  }

  Future<int> updateUserService(UserService service) async {
    final db = await database;
    final userId = _requireUserId();
    return db.update(
      'user_services',
      _owned(service.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [service.id, userId],
    );
  }

  Future<int> deleteUserService(int id) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'user_services',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ─────────────── STOCK QUERIES ───────────────

  /// Returns total quantity of a product sent to all sites
  Future<double> getTotalSentToSites(int productId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(quantity), 0) as total FROM site_products WHERE product_id = ? AND user_id = ?',
      [productId, userId],
    );
    return (rows.first['total'] as num).toDouble();
  }

  /// Adds stock to a store product
  Future<void> addStock(int productId, double quantity) async {
    final db = await database;
    final userId = _requireUserId();
    await db.rawUpdate('''
      UPDATE store_products
      SET stock = stock + ?, updated_at = ?
      WHERE id = ? AND user_id = ?
    ''', [quantity, DateTime.now().toIso8601String(), productId, userId]);
  }

  /// Sets stock to a specific value
  Future<void> setStock(int productId, double quantity) async {
    final db = await database;
    final userId = _requireUserId();
    await db.rawUpdate('''
      UPDATE store_products
      SET stock = ?, updated_at = ?
      WHERE id = ? AND user_id = ?
    ''', [quantity, DateTime.now().toIso8601String(), productId, userId]);
  }

  /// Returns products that are out/critical/low stock, ordered by severity.
  Future<List<StoreProduct>> getStockAlertProducts({int limit = 5}) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.rawQuery('''
      SELECT *
      FROM store_products
      WHERE user_id = ?
        AND (
          stock <= 0
          OR (stock > 0 AND stock <= COALESCE(low_stock_threshold, 10.0))
        )
      ORDER BY
        CASE
          WHEN stock <= 0 THEN 0
          WHEN stock <= COALESCE(critical_stock_threshold, 2.0) THEN 1
          ELSE 2
        END ASC,
        stock ASC,
        name ASC
      LIMIT ?
    ''', [userId, limit]);
    return rows.map(StoreProduct.fromMap).toList();
  }

  Future<List<WorkerModel>> getAllWorkers() async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'workers',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return rows.map(WorkerModel.fromMap).toList();
  }

  Future<WorkerModel?> getWorkerById(int id) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'workers',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return rows.isEmpty ? null : WorkerModel.fromMap(rows.first);
  }

  Future<List<WorkerModel>> getWorkersBySite(int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.rawQuery('''
      SELECT w.* FROM workers w
      INNER JOIN site_workers sw ON w.id = sw.worker_id
      WHERE sw.site_id = ? AND sw.user_id = ? AND w.user_id = ?
      ORDER BY w.name ASC
    ''', [siteId, userId, userId]);
    return rows.map(WorkerModel.fromMap).toList();
  }

  Future<List<WorkerModel>> getWorkersNotOnSite(int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.rawQuery('''
      SELECT * FROM workers
      WHERE user_id = ?
      AND id NOT IN (
        SELECT worker_id FROM site_workers WHERE site_id = ? AND user_id = ?
      )
      AND status = 'active'
      ORDER BY name ASC
    ''', [userId, siteId, userId]);
    return rows.map(WorkerModel.fromMap).toList();
  }

  Future<int> insertWorker(WorkerModel worker) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert('workers', _owned(worker.toMap(), userId));
  }

  Future<int> updateWorker(WorkerModel worker) async {
    final db = await database;
    final userId = _requireUserId();
    return db.update(
      'workers',
      _owned(worker.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [worker.id, userId],
    );
  }

  Future<int> deleteWorker(int id) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'workers',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ─────────────── WORKER DOCUMENTS ───────────────

  Future<List<WorkerDocument>> getWorkerDocuments(int workerId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'worker_documents',
      where: 'worker_id = ? AND user_id = ?',
      whereArgs: [workerId, userId],
      orderBy: 'uploaded_at DESC',
    );
    return rows.map(WorkerDocument.fromMap).toList();
  }

  Future<WorkerDocument?> getWorkerDocumentByType(
    int workerId,
    String documentType,
  ) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'worker_documents',
      where: 'worker_id = ? AND document_type = ? AND user_id = ?',
      whereArgs: [workerId, documentType, userId],
    );
    return rows.isEmpty ? null : WorkerDocument.fromMap(rows.first);
  }

  Future<int> insertWorkerDocument(WorkerDocument document) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert('worker_documents', _owned(document.toMap(), userId));
  }

  // ─────────────── DOCUMENTS (unified, v19) ───────────────

  Future<int> insertDocument(DocumentModel doc) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.insert('documents', _owned(doc.toMap(), userId));
  }

  Future<int> updateDocument(DocumentModel doc) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.update(
      'documents',
      _owned(doc.toMap(), userId),
      where: 'uuid = ? AND user_id = ?',
      whereArgs: [doc.uuid, userId],
    );
  }

  /// Soft delete: never removes the row (keeps file + history recoverable).
  Future<int> softDeleteDocument(String uuid) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.update(
      'documents',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'uuid = ? AND user_id = ?',
      whereArgs: [uuid, userId],
    );
  }

  /// Restore a soft-deleted document.
  Future<int> restoreDocument(String uuid) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.update(
      'documents',
      {
        'is_deleted': 0,
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'uuid = ? AND user_id = ?',
      whereArgs: [uuid, userId],
    );
  }

  /// Permanent delete (used only from the Trash after explicit purge).
  Future<int> hardDeleteDocument(String uuid) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.delete(
      'documents',
      where: 'uuid = ? AND user_id = ?',
      whereArgs: [uuid, userId],
    );
  }

  Future<DocumentModel?> getDocumentByUuid(String uuid) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'documents',
      where: 'uuid = ? AND user_id = ?',
      whereArgs: [uuid, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : DocumentModel.fromMap(rows.first);
  }

  /// All non-deleted documents (optionally scoped to an entity).
  Future<List<DocumentModel>> getDocuments({
    DocumentEntityType? entityType,
    int? entityId,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    final userId = _requireUserId();
    final where = <String>['user_id = ?'];
    final args = <Object?>[userId];
    if (!includeDeleted) where.add('is_deleted = 0');
    if (entityType != null) {
      where.add('entity_type = ?');
      args.add(entityType.apiValue);
    }
    if (entityId != null) {
      where.add('entity_id = ?');
      args.add(entityId);
    }
    final rows = await db.query(
      'documents',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );
    return rows.map(DocumentModel.fromMap).toList();
  }

  Future<List<DocumentModel>> searchDocuments(String query) async {
    final db = await database;
    final userId = _requireUserId();
    final q = '%${query.toLowerCase()}%';
    final rows = await db.query(
      'documents',
      where: 'user_id = ? AND is_deleted = 0 AND '
          '(LOWER(file_name) LIKE ? OR LOWER(category) LIKE ? OR uuid LIKE ?)',
      whereArgs: [userId, q, q, q],
      orderBy: 'updated_at DESC',
    );
    return rows.map(DocumentModel.fromMap).toList();
  }

  /// All documents pending/failed upload (offline queue + retry).
  Future<List<DocumentModel>> getDocumentsNeedingSync() async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'documents',
      where: 'user_id = ? AND sync_status IN (?, ?) AND is_deleted = 0',
      whereArgs: [userId, 'pending', 'failed'],
      orderBy: 'updated_at ASC',
    );
    return rows.map(DocumentModel.fromMap).toList();
  }

  Future<int> deleteWorkerDocument(int id) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'worker_documents',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> deleteWorkerDocumentsByWorker(int workerId) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'worker_documents',
      where: 'worker_id = ? AND user_id = ?',
      whereArgs: [workerId, userId],
    );
  }

  // ─────────────── WORKER PERFORMANCE ───────────────

  Future<List<WorkerPerformance>> getWorkerPerformance(int workerId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'worker_performance',
      where: 'worker_id = ? AND user_id = ?',
      whereArgs: [workerId, userId],
      orderBy: 'month DESC',
    );
    return rows.map(WorkerPerformance.fromMap).toList();
  }

  Future<WorkerPerformance?> getWorkerPerformanceForMonth(
    int workerId,
    DateTime month,
  ) async {
    final db = await database;
    final userId = _requireUserId();
    final monthStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
    final rows = await db.query(
      'worker_performance',
      where: 'worker_id = ? AND month = ? AND user_id = ?',
      whereArgs: [workerId, monthStr, userId],
    );
    return rows.isEmpty ? null : WorkerPerformance.fromMap(rows.first);
  }

  Future<int> insertWorkerPerformance(WorkerPerformance performance) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert(
      'worker_performance',
      _owned(performance.toMap(), userId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateWorkerPerformance(WorkerPerformance performance) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.update(
      'worker_performance',
      _owned(performance.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [performance.id, userId],
    );
  }

  Future<int> deleteWorkerPerformance(int id) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'worker_performance',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> deleteWorkerPerformanceByWorker(int workerId) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'worker_performance',
      where: 'worker_id = ? AND user_id = ?',
      whereArgs: [workerId, userId],
    );
  }

  // ─────────────── PAYROLL ───────────────

  Future<List<PayrollModel>> getPayrollForMonth(DateTime month) async {
    final db = await database;
    final userId = _requireUserId();
    final monthStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
    final rows = await db.rawQuery('''
      SELECT p.*, w.name AS worker_name, w.trade AS trade
      FROM payroll p
      INNER JOIN workers w ON p.worker_id = w.id AND w.user_id = p.user_id
      WHERE p.month = ? AND p.user_id = ?
      ORDER BY w.name ASC
    ''', [monthStr, userId]);
    return rows.map(PayrollModel.fromMap).toList();
  }

  Future<PayrollModel?> getPayroll(int workerId, DateTime month) async {
    final db = await database;
    final userId = _requireUserId();
    final monthStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
    final rows = await db.rawQuery('''
      SELECT p.*, w.name AS worker_name, w.trade AS trade
      FROM payroll p
      INNER JOIN workers w ON p.worker_id = w.id AND w.user_id = p.user_id
      WHERE p.worker_id = ? AND p.month = ? AND p.user_id = ?
    ''', [workerId, monthStr, userId]);
    return rows.isEmpty ? null : PayrollModel.fromMap(rows.first);
  }

  Future<int> insertPayroll(PayrollModel payroll) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    _notifyUserMutated();
    _notifyUserMutated();
    return db.insert(
      'payroll',
      _owned(payroll.toMap(), userId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePayroll(PayrollModel payroll) async {
    final db = await database;
    final userId = _requireUserId();
    return db.update(
      'payroll',
      _owned(payroll.toMap(), userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [payroll.id, userId],
    );
  }

  Future<int> deletePayroll(int id) async {
    final db = await database;
    final userId = _requireUserId();
    return db.delete(
      'payroll',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> setPayrollStatus(int id, String status) async {
    final db = await database;
    final userId = _requireUserId();
    return db.update(
      'payroll',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> assignWorkerToSite(int workerId, int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    await db.insert(
      'site_workers',
      {
        'user_id': userId,
        'site_id': siteId,
        'worker_id': workerId,
        'assigned_date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeWorkerFromSite(int workerId, int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    await db.delete(
      'site_workers',
      where: 'site_id = ? AND worker_id = ? AND user_id = ?',
      whereArgs: [siteId, workerId, userId],
    );
  }

  Future<List<SiteModel>> getSitesByWorker(int workerId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.rawQuery('''
      SELECT s.* FROM sites s
      INNER JOIN site_workers sw ON s.id = sw.site_id
      WHERE sw.worker_id = ? AND sw.user_id = ? AND s.user_id = ?
    ''', [workerId, userId, userId]);
    return rows.map(SiteModel.fromMap).toList();
  }

  Future<List<AttendanceModel>> getAttendanceByWorker(
    int workerId, {
    int? year,
    int? month,
  }) async {
    final db = await database;
    final userId = _requireUserId();
    String where = 'a.worker_id = ? AND a.user_id = ?';
    final args = <dynamic>[workerId, userId];

    if (year != null && month != null) {
      final start = '$year-${month.toString().padLeft(2, '0')}-01';
      final end = '$year-${month.toString().padLeft(2, '0')}-31';
      where += ' AND a.date >= ? AND a.date <= ?';
      args.addAll([start, end]);
    }

    final rows = await db.rawQuery('''
      SELECT a.*, s.name as site_name FROM attendance a
      LEFT JOIN sites s ON a.site_id = s.id AND s.user_id = a.user_id
      WHERE $where
      ORDER BY a.date DESC
    ''', args);
    return rows.map(AttendanceModel.fromMap).toList();
  }

  Future<AttendanceModel?> getAttendance(int workerId, String date) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'attendance',
      where: 'worker_id = ? AND date = ? AND user_id = ?',
      whereArgs: [workerId, date, userId],
    );
    return rows.isEmpty ? null : AttendanceModel.fromMap(rows.first);
  }

  /// Read-only: all attendance rows (with worker name) within an inclusive date
  /// range, for the current user. Used by the Calendar to render attendance
  /// events on their real days. No schema change.
  Future<List<Map<String, dynamic>>> getAttendanceInRange(
    String start,
    String end,
  ) async {
    final db = await database;
    final userId = _requireUserId();
    return db.rawQuery('''
      SELECT a.*, w.name AS worker_name
      FROM attendance a
      LEFT JOIN workers w ON a.worker_id = w.id AND w.user_id = a.user_id
      WHERE a.date >= ? AND a.date <= ? AND a.user_id = ?
      ORDER BY a.date ASC
    ''', [start, end, userId]);
  }

  Future<List<Map<String, dynamic>>> getSiteAttendanceForDate(
    int siteId,
    String date,
  ) async {
    final db = await database;
    final userId = _requireUserId();
    return db.rawQuery('''
      SELECT w.id, w.name, w.trade, w.daily_rate,
             COALESCE(a.type, 'absent') as attendance_type,
             a.id as attendance_id
      FROM workers w
      INNER JOIN site_workers sw ON w.id = sw.worker_id
        AND sw.site_id = ?
        AND sw.user_id = ?
      LEFT JOIN attendance a ON a.worker_id = w.id
        AND a.date = ?
        AND a.site_id = ?
        AND a.user_id = ?
      WHERE w.user_id = ?
      ORDER BY w.name ASC
    ''', [siteId, userId, date, siteId, userId, userId]);
  }

  Future<int> upsertAttendance(AttendanceModel att) async {
    final db = await database;
    final userId = _requireUserId();
    return db.insert(
      'attendance',
      _owned(att.toMap(), userId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, int>> getMonthlyAttendanceSummary(
    int workerId,
    int year,
    int month,
  ) async {
    final db = await database;
    final userId = _requireUserId();
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final end = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await db.rawQuery('''
      SELECT type, COUNT(*) as count FROM attendance
      WHERE worker_id = ? AND user_id = ? AND date >= ? AND date <= ?
      GROUP BY type
    ''', [workerId, userId, start, end]);
    final summary = <String, int>{'full': 0, 'half': 0, 'absent': 0};
    for (final r in rows) {
      summary[r['type'] as String] = r['count'] as int;
    }
    return summary;
  }

  Future<List<AdvancePaymentModel>> getAdvancesByWorker(int workerId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'advance_payments',
      where: 'worker_id = ? AND user_id = ?',
      whereArgs: [workerId, userId],
      orderBy: 'request_date DESC',
    );
    return rows.map(AdvancePaymentModel.fromMap).toList();
  }

  Future<List<AdvancePaymentModel>> getAllPendingAdvances() async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.rawQuery('''
      SELECT ap.*, w.name as worker_name
      FROM advance_payments ap
      INNER JOIN workers w ON ap.worker_id = w.id AND w.user_id = ap.user_id
      WHERE ap.status = 'pending' AND ap.user_id = ?
      ORDER BY ap.request_date ASC
    ''', [userId]);
    return rows.map(AdvancePaymentModel.fromMap).toList();
  }

  Future<int> insertAdvance(AdvancePaymentModel advance) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();
    return db.insert('advance_payments', _owned(advance.toMap(), userId));
  }

  Future<int> approveAdvance(int advanceId) async {
    final db = await database;
    final userId = _requireUserId();
    return db.update(
      'advance_payments',
      {'status': 'approved', 'approved_date': DateTime.now().toIso8601String()},
      where: 'id = ? AND user_id = ?',
      whereArgs: [advanceId, userId],
    );
  }

  Future<int> rejectAdvance(int advanceId) async {
    final db = await database;
    final userId = _requireUserId();
    return db.update(
      'advance_payments',
      {'status': 'rejected', 'approved_date': DateTime.now().toIso8601String()},
      where: 'id = ? AND user_id = ?',
      whereArgs: [advanceId, userId],
    );
  }

  Future<double> getApprovedAdvancesTotal(
    int workerId, {
    int? year,
    int? month,
  }) async {
    final db = await database;
    final userId = _requireUserId();
    String where = 'worker_id = ? AND user_id = ? AND status = ?';
    final args = <dynamic>[workerId, userId, 'approved'];

    if (year != null && month != null) {
      // Use strftime to extract year-month from the ISO datetime stored in
      // approved_date. String-prefix comparison would be brittle against
      // timestamps that include a timezone offset or vary in format.
      final monthStr = '$year-${month.toString().padLeft(2, '0')}';
      where += " AND strftime('%Y-%m', approved_date) = ?";
      args.add(monthStr);
    }

    final rows = await db.rawQuery(
      'SELECT SUM(amount) as total FROM advance_payments WHERE $where',
      args,
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<ConstructionPaymentModel>> getConstructionPaymentsBySite(
      int siteId) async {
    final db = await database;
    final userId = _requireUserId();
    final rows = await db.query(
      'site_construction_payments',
      where: 'site_id = ? AND user_id = ?',
      whereArgs: [siteId, userId],
      orderBy: 'payment_date DESC',
    );
    return rows.map(ConstructionPaymentModel.fromMap).toList();
  }

  Future<int> insertConstructionPayment(
      ConstructionPaymentModel payment) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();

    return await db.transaction((txn) async {
      final id = await txn.insert(
          'site_construction_payments', _owned(payment.toMap(), userId));

      await txn.rawUpdate('''
        UPDATE sites 
        SET construction_paid = construction_paid + ?,
            last_paid_date = ?
        WHERE id = ? AND user_id = ?
      ''', [
        payment.amount,
        payment.paymentDate.toIso8601String(),
        payment.siteId,
        userId
      ]);

      return id;
    });
  }

  Future<int> deleteConstructionPayment(
      int paymentId, int siteId, double amount) async {
    final db = await database;
    final userId = _requireUserId();
    _notifyUserMutated();

    return await db.transaction((txn) async {
      final count = await txn.delete(
        'site_construction_payments',
        where: 'id = ? AND user_id = ?',
        whereArgs: [paymentId, userId],
      );

      if (count > 0) {
        await txn.rawUpdate('''
          UPDATE sites 
          SET construction_paid = construction_paid - ?
          WHERE id = ? AND user_id = ?
        ''', [amount, siteId, userId]);
      }

      return count;
    });
  }

  Future<int> updateConstructionPayment(
    int paymentId,
    double oldAmount,
    ConstructionPaymentModel payment,
  ) async {
    final db = await database;
    final userId = _requireUserId();
    final diff = payment.amount - oldAmount;
    _notifyUserMutated();

    return await db.transaction((txn) async {
      final count = await txn.update(
        'site_construction_payments',
        {
          'amount': payment.amount,
          'payment_date': payment.paymentDate.toIso8601String(),
          'notes': payment.notes,
          'updated_at': payment.updatedAt.toIso8601String(),
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [paymentId, userId],
      );

      if (count > 0) {
        await txn.rawUpdate('''
          UPDATE sites
          SET construction_paid = construction_paid + ?,
              last_paid_date = CASE
                WHEN ? > COALESCE(last_paid_date, '') THEN ?
                ELSE last_paid_date
              END
          WHERE id = ? AND user_id = ?
        ''', [
          diff,
          payment.paymentDate.toIso8601String(),
          payment.paymentDate.toIso8601String(),
          payment.siteId,
          userId,
        ]);
      }

      return count;
    });
  }

  /// Returns dashboard statistics for professional dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final userId = _requireUserId();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // All site aggregates in one pass.
    final siteRow = (await db.rawQuery('''
      SELECT
        SUM(CASE WHEN status = 'active'    THEN 1 ELSE 0 END) AS activeSites,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completedSites,
        SUM(estimated_cost)   AS totalCost,
        SUM(advance_received + COALESCE(construction_paid, 0)) AS totalPaid,
        SUM(CASE WHEN final_cost IS NOT NULL THEN final_cost ELSE estimated_cost END -
            (advance_received + COALESCE(construction_paid, 0))) AS totalPending
      FROM sites WHERE user_id = ?
    ''', [userId])).first;

    final activeWorkers = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM workers WHERE status = 'active' AND user_id = ?",
            [userId],
          ),
        ) ??
        0;

    final pendingAdvances = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM advance_payments WHERE status = 'pending' AND user_id = ?",
            [userId],
          ),
        ) ??
        0;

    // Workers present/absent today
    final attendanceRow = (await db.rawQuery('''
      SELECT
        SUM(CASE WHEN type = 'full' OR type = 'half' THEN 1 ELSE 0 END) AS presentToday,
        SUM(CASE WHEN type = 'absent' THEN 1 ELSE 0 END) AS absentToday
      FROM attendance WHERE date = ? AND user_id = ?
    ''', [today, userId])).first;

    // Total products in store
    final totalProducts = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM store_products WHERE user_id = ?",
            [userId],
          ),
        ) ??
        0;

    final stockAlertRow = (await db.rawQuery('''
      SELECT
        SUM(CASE WHEN stock <= 0 THEN 1 ELSE 0 END) AS outOfStock,
        SUM(CASE
              WHEN stock > 0 AND stock <= COALESCE(critical_stock_threshold, 2.0)
              THEN 1 ELSE 0 END) AS criticalStock,
        SUM(CASE
              WHEN stock > COALESCE(critical_stock_threshold, 2.0)
               AND stock <= COALESCE(low_stock_threshold, 10.0)
              THEN 1 ELSE 0 END) AS lowStock
      FROM store_products
      WHERE user_id = ?
    ''', [userId])).first;

    // Materials issued today (site_products created today)
    final materialsIssuedToday = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM site_products WHERE DATE(created_at) = ? AND user_id = ?",
            [today, userId],
          ),
        ) ??
        0;

    // Today's expenses (advance payments approved today)
    final expensesRow = (await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS totalExpenses
      FROM advance_payments
      WHERE status = 'approved' AND DATE(approved_date) = ? AND user_id = ?
    ''', [today, userId])).first;

    return {
      'activeSites': (siteRow['activeSites'] as num?)?.toInt() ?? 0,
      'completedSites': (siteRow['completedSites'] as num?)?.toInt() ?? 0,
      'activeWorkers': activeWorkers,
      'totalProjectCost': (siteRow['totalCost'] as num?)?.toDouble() ?? 0.0,
      'totalPaidAmount': (siteRow['totalPaid'] as num?)?.toDouble() ?? 0.0,
      'pendingAdvances': pendingAdvances,
      'workersPresentToday':
          (attendanceRow['presentToday'] as num?)?.toInt() ?? 0,
      'workersAbsentToday':
          (attendanceRow['absentToday'] as num?)?.toInt() ?? 0,
      'totalProducts': totalProducts,
      'outOfStock': (stockAlertRow['outOfStock'] as num?)?.toInt() ?? 0,
      'criticalStock': (stockAlertRow['criticalStock'] as num?)?.toInt() ?? 0,
      'lowStock': (stockAlertRow['lowStock'] as num?)?.toInt() ?? 0,
      'materialsIssuedToday': materialsIssuedToday,
      'pendingPayments': (siteRow['totalPending'] as num?)?.toDouble() ?? 0.0,
      'todayExpenses':
          (expensesRow['totalExpenses'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Read-only: recent activity feed composed from existing tables.
  /// Returns up to [limit] items, newest first, each:
  /// { type, title, subtitle, time } where time is an ISO timestamp.
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 8}) async {
    final db = await database;
    final userId = _requireUserId();

    final workers = (await db.rawQuery('''
      SELECT 'worker' AS type, name AS title,
             'New worker added' AS subtitle, created_at AS time
      FROM workers WHERE user_id = ?
    ''', [userId])).cast<Map<String, dynamic>>();

    final materials = (await db.rawQuery('''
      SELECT 'material' AS type,
             (SELECT name FROM products p WHERE p.id = sp.product_id) AS title,
             (SELECT name FROM sites s WHERE s.id = sp.site_id) AS subtitle,
             sp.created_at AS time
      FROM site_products sp WHERE sp.user_id = ?
    ''', [userId])).cast<Map<String, dynamic>>();

    final payments = (await db.rawQuery('''
      SELECT 'payment' AS type,
             'Payment received' AS title,
             (SELECT name FROM sites s WHERE s.id = scp.site_id) AS subtitle,
             scp.payment_date AS time
      FROM site_construction_payments scp WHERE scp.user_id = ?
    ''', [userId])).cast<Map<String, dynamic>>();

    final expenses = (await db.rawQuery('''
      SELECT 'expense' AS type, 'Expense added' AS title,
             notes AS subtitle, approved_date AS time
      FROM advance_payments
      WHERE user_id = ? AND status = 'approved' AND approved_date IS NOT NULL
    ''', [userId])).cast<Map<String, dynamic>>();

    final all = <Map<String, dynamic>>[
      ...workers,
      ...materials,
      ...payments,
      ...expenses,
    ];
    all.sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
    return all.take(limit).toList();
  }

  // ─────────────── CHART DATA QUERIES ───────────────

  /// Returns attendance data for the last 30 days grouped by date
  Future<List<Map<String, dynamic>>> getAttendanceChartData() async {
    final db = await database;
    final userId = _requireUserId();
    final thirtyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String()
        .split('T')[0];

    final rows = await db.rawQuery('''
      SELECT 
        date,
        SUM(CASE WHEN type = 'full' THEN 1 ELSE 0 END) AS full_count,
        SUM(CASE WHEN type = 'half' THEN 1 ELSE 0 END) AS half_count,
        SUM(CASE WHEN type = 'absent' THEN 1 ELSE 0 END) AS absent_count
      FROM attendance
      WHERE date >= ? AND user_id = ?
      GROUP BY date
      ORDER BY date ASC
    ''', [thirtyDaysAgo, userId]);

    return rows;
  }

  /// Returns site progress data (name and completion percentage)
  Future<List<Map<String, dynamic>>> getSiteProgressChartData() async {
    final db = await database;
    final userId = _requireUserId();

    final rows = await db.rawQuery('''
      SELECT 
        name,
        CASE 
          WHEN final_cost IS NOT NULL 
          THEN (advance_received + COALESCE(construction_paid, 0)) * 100.0 / final_cost
          ELSE (advance_received + COALESCE(construction_paid, 0)) * 100.0 / estimated_cost
        END AS progress_percentage,
        status
      FROM sites
      WHERE user_id = ? AND status != 'completed'
      ORDER BY progress_percentage ASC
    ''', [userId]);

    return rows;
  }

  /// Returns material usage data (top 10 products by total quantity sent to sites)
  Future<List<Map<String, dynamic>>> getMaterialUsageChartData() async {
    final db = await database;
    final userId = _requireUserId();

    final rows = await db.rawQuery('''
      SELECT 
        sp.product_id,
        p.name AS product_name,
        SUM(sp.quantity) AS total_quantity
      FROM site_products sp
      INNER JOIN products p ON sp.product_id = p.id AND p.user_id = sp.user_id
      WHERE sp.user_id = ?
      GROUP BY sp.product_id, p.name
      ORDER BY total_quantity DESC
      LIMIT 10
    ''', [userId]);

    return rows;
  }

  /// Returns expenses data for the last 30 days (approved advance payments)
  Future<List<Map<String, dynamic>>> getExpensesChartData() async {
    final db = await database;
    final userId = _requireUserId();
    final thirtyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String()
        .split('T')[0];

    final rows = await db.rawQuery('''
      SELECT 
        DATE(approved_date) AS date,
        SUM(amount) AS total_amount
      FROM advance_payments
      WHERE status = 'approved' AND DATE(approved_date) >= ? AND user_id = ?
      GROUP BY DATE(approved_date)
      ORDER BY date ASC
    ''', [thirtyDaysAgo, userId]);

    return rows;
  }

  /// Returns payments data for the last 30 days (construction payments)
  Future<List<Map<String, dynamic>>> getPaymentsChartData() async {
    final db = await database;
    final userId = _requireUserId();
    final thirtyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String()
        .split('T')[0];

    final rows = await db.rawQuery('''
      SELECT 
        DATE(payment_date) AS date,
        SUM(amount) AS total_amount
      FROM site_construction_payments
      WHERE DATE(payment_date) >= ? AND user_id = ?
      GROUP BY DATE(payment_date)
      ORDER BY date ASC
    ''', [thirtyDaysAgo, userId]);

    return rows;
  }

  /// Monthly revenue (construction payments) for the last [months] months,
  /// grouped by YYYY-MM. Read-only aggregation for the Analytics screen.
  Future<List<Map<String, dynamic>>> getMonthlyRevenueChartData(
      {int months = 12}) async {
    final db = await database;
    final userId = _requireUserId();
    final since = DateTime(DateTime.now().year, DateTime.now().month - (months - 1))
        .toIso8601String()
        .split('T')[0];

    return db.rawQuery('''
      SELECT
        substr(payment_date, 1, 7) AS month,
        SUM(amount) AS total_amount
      FROM site_construction_payments
      WHERE DATE(payment_date) >= ? AND user_id = ?
      GROUP BY month
      ORDER BY month ASC
    ''', [since, userId]);
  }

  /// Monthly payroll net-salary totals for the last [months] months, grouped
  /// by the payroll `month` column (YYYY-MM). Read-only aggregation.
  Future<List<Map<String, dynamic>>> getMonthlyPayrollChartData(
      {int months = 12}) async {
    final db = await database;
    final userId = _requireUserId();
    final since = DateTime(DateTime.now().year, DateTime.now().month - (months - 1))
        .toIso8601String()
        .substring(0, 7);

    return db.rawQuery('''
      SELECT
        month,
        SUM(net_salary) AS total_amount,
        COUNT(*) AS payslips
      FROM payroll
      WHERE month >= ? AND user_id = ?
      GROUP BY month
      ORDER BY month ASC
    ''', [since, userId]);
  }

  Future<bool> hasUserData(int userId) async {
    final db = await database;
    for (final table in [
      'sites',
      'workers',
      'store_products',
      'user_services',
      'attendance',
      'advance_payments',
      'site_construction_payments',
      'payroll',
    ]) {
      final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $table WHERE user_id = ?',
        [userId],
      ));
      if ((count ?? 0) > 0) return true;
    }
    return false;
  }

  /// Counts user-owned rows in every syncable table. Used by the cloud sync
  /// service to log per-table record counts and to guard against uploading an
  /// empty database. Centralized here so the sync service never writes raw
  /// SQL against [DatabaseHelper].
  Future<Map<String, int>> countUserRecords(int userId) async {
    final db = await database;
    final counts = <String, int>{};
    for (final table in [
      'sites',
      'workers',
      'store_products',
      'user_services',
      'attendance',
      'advance_payments',
      'site_construction_payments',
      'products',
      'site_workers',
      'site_products',
      'site_services',
      // These must mirror exportUserData() exactly. If a table is exported
      // but not counted here, a user whose only data lives in it would be
      // wrongly reported as "empty" and the upload would be blocked — even
      // though real data exists (and the UI shows it).
      'worker_documents',
      'worker_performance',
      'payroll',
      'documents',
    ]) {
      counts[table] = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $table WHERE user_id = ?',
              [userId],
            ),
          ) ??
          0;
    }
    return counts;
  }

  Future<Map<String, dynamic>> exportUserData(int userId) async {
    final db = await database;
    return {
      'schema': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'sites': await db.query('sites',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'workers': await db.query('workers',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'products': await db.query('products',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'siteWorkers': await db.query('site_workers',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'attendance': await db.query('attendance',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'advances': await db.query('advance_payments',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'storeProducts': await db.query('store_products',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'siteProducts': await db.query('site_products',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'siteServices': await db.query('site_services',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'userServices': await db.query('user_services',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'constructionPayments': await db.query('site_construction_payments',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'workerDocuments': await db.query('worker_documents',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'workerPerformance': await db.query('worker_performance',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'payroll': await db.query('payroll',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
      'documents': await db.query('documents',
          where: 'user_id = ?', whereArgs: [userId], orderBy: 'id ASC'),
    };
  }

  Future<void> replaceUserData(int userId, Map<String, dynamic> data) async {
    _suppressMutateNotify = true;
    try {
      final db = await database;
      await db.transaction((txn) async {
      await txn.delete('site_construction_payments',
          where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete(
        'advance_payments',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      await txn.delete('attendance', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('site_workers', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('products', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('site_services', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('site_products', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('store_products', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('user_services', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('worker_documents',
          where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('worker_performance',
          where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('payroll', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('documents', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('workers', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('sites', where: 'user_id = ?', whereArgs: [userId]);

      final siteIds = <int, int>{};
      final workerIds = <int, int>{};

      for (final row in List<Map<String, dynamic>>.from(data['sites'] ?? [])) {
        final oldId = (row['id'] as num).toInt();
        final newId = await txn.insert('sites', _insertable(row, userId));
        siteIds[oldId] = newId;
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['workers'] ?? [])) {
        final oldId = (row['id'] as num).toInt();
        final newId = await txn.insert('workers', _insertable(row, userId));
        workerIds[oldId] = newId;
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['products'] ?? [])) {
        final map = _insertable(row, userId, siteIds: siteIds);
        if (map['site_id'] != null) {
          await txn.insert('products', map);
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['siteWorkers'] ?? [])) {
        final map =
            _insertable(row, userId, siteIds: siteIds, workerIds: workerIds);
        if (map['site_id'] != null && map['worker_id'] != null) {
          await txn.insert(
            'site_workers',
            map,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['attendance'] ?? [])) {
        final map =
            _insertable(row, userId, siteIds: siteIds, workerIds: workerIds);
        if (map['site_id'] != null && map['worker_id'] != null) {
          await txn.insert(
            'attendance',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['advances'] ?? [])) {
        final map = _insertable(row, userId, workerIds: workerIds);
        if (map['worker_id'] != null) {
          await txn.insert('advance_payments', map);
        }
      }

      final storeProductIds = <int, int>{};
      for (final row
          in List<Map<String, dynamic>>.from(data['storeProducts'] ?? [])) {
        final oldId = (row['id'] as num).toInt();
        final newId =
            await txn.insert('store_products', _insertable(row, userId));
        storeProductIds[oldId] = newId;
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['siteProducts'] ?? [])) {
        final map = _insertable(row, userId, siteIds: siteIds);
        if (map['product_id'] != null &&
            storeProductIds.containsKey(map['product_id'])) {
          map['product_id'] = storeProductIds[map['product_id']];
          if (map['site_id'] != null) {
            // ignore conflict so re-imports don't fail
            await txn.insert('site_products', map,
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['siteServices'] ?? [])) {
        final map = _insertable(row, userId, siteIds: siteIds);
        if (map['site_id'] != null) {
          await txn.insert('site_services', map,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['userServices'] ?? [])) {
        await txn.insert('user_services', _insertable(row, userId),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      for (final row in List<Map<String, dynamic>>.from(
          data['constructionPayments'] ?? [])) {
        final map = _insertable(row, userId, siteIds: siteIds);
        if (map['site_id'] != null) {
          await txn.insert('site_construction_payments', map,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['workerDocuments'] ?? [])) {
        final map = _insertable(row, userId, workerIds: workerIds);
        if (map['worker_id'] != null) {
          await txn.insert('worker_documents', map,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['workerPerformance'] ?? [])) {
        final map = _insertable(row, userId, workerIds: workerIds);
        if (map['worker_id'] != null) {
          await txn.insert('worker_performance', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      for (final row
          in List<Map<String, dynamic>>.from(data['payroll'] ?? [])) {
        final map = _insertable(row, userId, workerIds: workerIds);
        if (map['worker_id'] != null) {
          await txn.insert('payroll', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Documents carry a stable `uuid` (no device-local id remap needed), so
      // they re-import verbatim. The binary file itself is synchronized via
      // Firebase Storage (handled by DocumentStorageService), not this JSON.
      for (final row
          in List<Map<String, dynamic>>.from(data['documents'] ?? [])) {
        await txn.insert('documents', _insertable(row, userId),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    } finally {
      _suppressMutateNotify = false;
    }
  }
}
