import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/data_source_exception.dart';
import '../models/dependencia_dto.dart';

class LocalDependenciaDataSource {
  final DatabaseHelper _databaseHelper;

  LocalDependenciaDataSource({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  Future<List<DependenciaDTO>> getDependenciasByDoctor(String doctorId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tableDependencias,
        where: 'doctor_id = ?',
        whereArgs: [doctorId],
        orderBy: 'tipo ASC, nombre ASC',
      );
      return maps.map((map) => DependenciaDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException(
        'Error al obtener dependencias del doctor',
        originalError: e,
      );
    }
  }

  Future<void> insertDependencia(DependenciaDTO dependencia) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        AppConstants.tableDependencias,
        dependencia.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw DataSourceException(
        'Error al insertar dependencia',
        originalError: e,
      );
    }
  }
}
