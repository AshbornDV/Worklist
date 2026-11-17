import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worklist/core/database/database_helper.dart';

/// Id of the account created by [openSeeded]. `seed.sql` hardcodes
/// `user_id = 1`, so a fresh database must yield exactly this id.
const int goldenUserId = 1;

bool _ffiInstalled = false;

/// Helper returned by the first successful [openSeeded] call in an isolate.
DatabaseHelper? _seededHelper;

/// Points sqflite at the FFI factory and deletes the database file left over
/// from a previous run. Call this from `setUpAll` (or once per test file):
/// every characterization suite shares one database file, so tests must run
/// with `--concurrency=1`.
Future<void> initCharacterizationEnvironment() async {
  if (!_ffiInstalled) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _ffiInstalled = true;
  }
  final dbPath = p.join(
    await databaseFactory.getDatabasesPath(),
    'worklist.db',
  );
  await databaseFactory.deleteDatabase(dbPath);
}

/// Opens a fresh [DatabaseHelper] against the shared characterization database
/// and loads [seedPath] into it.
///
/// The account is created through [DatabaseHelper.createAccount] so the schema
/// creation path is the one the app uses; [goldenUserId] proves the seed's
/// hardcoded `user_id = 1` lines up with the account row.
///
/// The first call in an isolate deletes the stale database file. Later calls
/// reuse the already-open connection: sqflite closes it when the file is
/// deleted, while [DatabaseHelper] keeps a static (now dead) handle, so a
/// repeated file delete would poison every later query with "This database has
/// already been closed". Instead the data is wiped in place through SQL, which
/// gives each call the same pristine state.
Future<DatabaseHelper> openSeeded({
  String seedPath = 'test/characterization/seed.sql',
}) async {
  final existing = _seededHelper;
  if (existing != null) {
    await existing.runRawSqlScript('DELETE FROM users');
    await existing.runRawSqlScript('DELETE FROM sqlite_sequence');
  } else {
    await initCharacterizationEnvironment();
  }

  final db = existing ?? DatabaseHelper();
  final user = await db.createAccount('fixture-user', 'fixture-pass');
  expect(
    user.id,
    goldenUserId,
    reason: 'seed.sql hardcodes user_id = $goldenUserId',
  );
  db.setActiveUser(user);
  await db.runRawSqlScript(File(seedPath).readAsStringSync());
  _seededHelper = db;
  return db;
}

/// Compares [actual] against `contracts/expectations/<name>.json`.
///
/// Dates become ISO-8601 strings and maps/lists are walked recursively; doubles
/// are left as numbers so SQLite `NUMERIC` columns stay stable across runs.
/// Run the suite with `--dart-define=UPDATE_GOLDENS=true` to rewrite the file.
void expectGolden(String name, Object? actual) {
  final file = File(
    p.join(Directory.current.path, 'contracts', 'expectations', '$name.json'),
  );
  final encoded = const JsonEncoder.withIndent('  ').convert(_normalise(actual));

  if (const bool.fromEnvironment('UPDATE_GOLDENS')) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('$encoded\n');
    return;
  }

  expect(
    file.existsSync(),
    isTrue,
    reason: 'Missing contract ${file.path}. '
        'Regenerate it with --dart-define=UPDATE_GOLDENS=true.',
  );
  expect(
    encoded,
    file.readAsStringSync().trimRight(),
    reason: 'Contract $name drifted from the frozen Flutter behaviour.',
  );
}

Object? _normalise(Object? value) {
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Map) {
    return value.map<String, Object?>(
      (key, entry) => MapEntry(key.toString(), _normalise(entry)),
    );
  }
  if (value is List) {
    return value.map(_normalise).toList();
  }
  return value;
}

/// Number of rows in [table], counted through the open connection.
Future<int> countRows(DatabaseHelper db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
  return (rows.first['c'] as num).toInt();
}
