import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:opti_flow/core/database/database_helper.dart';
import 'package:opti_flow/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await DatabaseHelper().close();
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

  test('DB-S1-16: batch insert multiple rows', () async {
    final now = DateTime.now().toIso8601String();
    final rows = List.generate(3, (i) => {
      'id': 'emp-test-$i',
      'nombre': 'Empresa $i',
      'lugar': 'Lugar $i',
      'activa': 1,
      'created_at': now,
      'updated_at': now,
    });

    await DatabaseHelper().batchInsert(AppConstants.tableEmpresas, rows);

    final db = await DatabaseHelper().database;
    final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM ${AppConstants.tableEmpresas}');
    expect(result.first['cnt'], 3);
  });

  test('DB-S1-16: batch insert empty list does nothing', () async {
    await DatabaseHelper().batchInsert(AppConstants.tableEmpresas, []);
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM ${AppConstants.tableEmpresas}');
    expect(result.first['cnt'], 0);
  });

  test('DB-S1-16: concurrent database access returns same instance', () async {
    final results = await Future.wait([
      DatabaseHelper().database,
      DatabaseHelper().database,
      DatabaseHelper().database,
    ]);
    // All should return the same database object
    expect(results[0], same(results[1]));
    expect(results[0], same(results[2]));
  });

  test('DB-S1-16: close and reopen works', () async {
    final db1 = await DatabaseHelper().database;
    expect(db1.isOpen, true);

    await DatabaseHelper().close();
    expect(db1.isOpen, false);

    final db2 = await DatabaseHelper().database;
    expect(db2.isOpen, true);
  });
}
