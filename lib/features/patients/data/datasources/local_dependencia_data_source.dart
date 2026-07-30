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
      final maps = await db.rawQuery(
        '''
        SELECT DISTINCT d.*
        FROM ${AppConstants.tableDependencias} d
        LEFT JOIN ${AppConstants.tableDoctorCampana} dc
          ON d.campana_id = dc.campana_id
        WHERE d.doctor_id = ? OR dc.doctor_id = ?
        ORDER BY d.tipo ASC, d.nombre ASC
        ''',
        [doctorId, doctorId],
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
