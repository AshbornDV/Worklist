import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../models/construction_payment_model.dart';
import '../models/advance_payment_model.dart';
import '../models/attendance_model.dart';
import '../models/product_model.dart';
import '../models/site_model.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;
  static Future<Database>? _dbInit;
  int? _activeUserId;

  int? get activeUserId => _activeUserId;

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
      version: 8,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createBusinessTables(db);
    await _createIndexes(db);
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
        status TEXT DEFAULT 'active',
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
    return db.insert('sites', _owned(site.toMap(), userId));
  }

  Future<int> updateSite(SiteModel site) async {
    final db = await database;
    final userId = _requireUserId();
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

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    final userId = _requireUserId();
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
    return db.delete(
      'products',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
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

  Future<int> deleteConstructionPayment(int paymentId, int siteId, double amount) async {
    final db = await database;
    final userId = _requireUserId();

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

  /// Returns dashboard statistics in 3 queries instead of the original 6,
  /// using conditional aggregation for the site-level metrics.
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final userId = _requireUserId();

    // All site aggregates in one pass.
    final siteRow = (await db.rawQuery('''
      SELECT
        SUM(CASE WHEN status = 'active'    THEN 1 ELSE 0 END) AS activeSites,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completedSites,
        SUM(estimated_cost)   AS totalCost,
        SUM(advance_received + COALESCE(construction_paid, 0)) AS totalPaid
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

    return {
      'activeSites': (siteRow['activeSites'] as num?)?.toInt() ?? 0,
      'completedSites': (siteRow['completedSites'] as num?)?.toInt() ?? 0,
      'activeWorkers': activeWorkers,
      'totalProjectCost': (siteRow['totalCost'] as num?)?.toDouble() ?? 0.0,
      'totalPaidAmount': (siteRow['totalPaid'] as num?)?.toDouble() ?? 0.0,
      'pendingAdvances': pendingAdvances,
    };
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
    };
  }

  Future<void> replaceUserData(int userId, Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'advance_payments',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      await txn.delete('attendance', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('site_workers', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('products', where: 'user_id = ?', whereArgs: [userId]);
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
    });
  }
}
