import 'package:flutter_test/flutter_test.dart';
import 'package:worklist/core/models/attendance_model.dart';
import 'harness.dart';

void main() {
  test('dashboard contract matches the frozen Flutter output', () async {
    final db = await openSeeded();
    expectGolden('dashboard.stats', await db.getDashboardStats());
    expectGolden('sites.all', (await db.getAllSites()).map((s) => s.toMap()).toList());
    expectGolden('sites.workers', (await db.getWorkersBySite(1)).map((w) => w.toMap()).toList());
  });

  test('attendance replace and worker cascade match the frozen behaviour', () async {
    final db = await openSeeded();

    // The seed gives Anil a `full` row on 2026-03-02.
    final before = await db.getAttendance(1, '2026-03-02');
    await db.upsertAttendance(AttendanceModel(
      workerId: 1,
      siteId: 1,
      date: '2026-03-02',
      type: 'half',
      createdAt: DateTime(2026, 3, 2, 18),
    ));
    final after = await db.getAttendance(1, '2026-03-02');

    expectGolden('constraints', {
      'attendanceRowsTotal': await countRows(db, 'attendance'),
      'beforeType': before?.type,
      'afterType': after?.type,
      'rowWasReplacedNotAppended': after?.id != before?.id,
    });

    await db.deleteWorker(1);

    expectGolden('cascade', {
      'siteWorkersForDeletedWorker': (await db.rawQuery(
        'SELECT COUNT(*) AS c FROM site_workers WHERE worker_id = 1',
      )).first['c'],
      'attendanceForDeletedWorker': (await db.rawQuery(
        'SELECT COUNT(*) AS c FROM attendance WHERE worker_id = 1',
      )).first['c'],
      'workersRemaining': (await db.getAllWorkers()).length,
    });
  });
}
