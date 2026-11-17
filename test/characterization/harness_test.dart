import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';

void main() {
  test('harness seeds sites visible through the repository', () async {
    final db = await openSeeded();
    final sites = await db.getAllSites();
    expect(sites, hasLength(3));
    expect(
      sites.map((s) => s.name),
      containsAll(['Maple Tower', 'Birch Villa', 'Cedar Depot']),
    );
  });
}
