import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../models/campana_dto.dart';

class LocalCampanaDataSource {
  final DatabaseHelper _databaseHelper;

  LocalCampanaDataSource({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  Future<void> insertCampana(CampanaDTO campana) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        AppConstants.tableCampanas,
        campana.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw Exception('Error al insertar campaña: $e');
    }
  }

  Future<List<CampanaDTO>> getCampanasByDoctor(String doctorId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT c.*
        FROM ${AppConstants.tableCampanas} c
        INNER JOIN ${AppConstants.tableDoctorCampana} dc
          ON c.id = dc.campana_id
        WHERE dc.doctor_id = ?
        ORDER BY c.created_at DESC
        ''',
        [doctorId],
      );
      return maps.map((map) => CampanaDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw Exception('Error al obtener campañas: $e');
    }
  }

  Future<bool> checkDuplicate(String nombreEmpresa, String lugar) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM ${AppConstants.tableCampanas}
        WHERE nombre_empresa = ? AND lugar = ?
        ''',
        [nombreEmpresa, lugar],
      );
      final count = result.first['count'] as int;
      return count > 0;
    } on DatabaseException catch (e) {
      throw Exception('Error al verificar duplicado: $e');
    }
  }

  Future<void> assignDoctor(String campanaId, String doctorId) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        AppConstants.tableDoctorCampana,
        {
          'id': const Uuid().v4(),
          'doctor_id': doctorId,
          'campana_id': campanaId,
          'asignado_en': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw Exception('Error al asignar doctor a campaña: $e');
    }
  }
}
