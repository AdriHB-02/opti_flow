import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:opti_flow/core/database/database_helper.dart';
import 'package:opti_flow/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/${AppConstants.dbName}');
  });

  test('DB-S1-14: create DB → insert 1 doctor → read → verify', () async {
    final db = await DatabaseHelper().database;
    final now = DateTime.now().toIso8601String();

    await db.insert(AppConstants.tableDoctores, {
      'id': 'doc-test-1',
      'nombre': 'Dr. Test',
      'email': 'test@voi.com',
      'rol': 'USER',
      'activo': 1,
      'created_at': now,
      'updated_at': now,
    });

    final results = await db.query(
      AppConstants.tableDoctores,
      where: 'id = ?',
      whereArgs: ['doc-test-1'],
    );

    expect(results.length, 1);
    expect(results[0]['nombre'], 'Dr. Test');
    expect(results[0]['email'], 'test@voi.com');
    expect(results[0]['rol'], 'USER');
    expect(results[0]['activo'], 1);
  });
}
