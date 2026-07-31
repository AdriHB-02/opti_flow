import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/data_source_exception.dart';
import '../../../../features/auth/data/models/user_dto.dart';
import '../models/campana_dto.dart';
import '../models/doctor_progress_dto.dart';

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

      await _databaseHelper.insertSyncLogEntry({
        'id': const Uuid().v4(),
        'doctor_id': campana.creadoPor,
        'tabla_afectada': AppConstants.tableCampanas,
        'registro_id': campana.id,
        'operacion': 'INSERT',
        'fecha_local': DateTime.now().toIso8601String(),
        'sincronizado': 0,
        'fecha_sync': null,
        'intentos': 0,
      });
    } on DatabaseException catch (e) {
      debugPrint('[DataSource] insertCampana error: $e');
      debugPrint('[DataSource] campana.toMap(): ${campana.toMap()}');
      throw DataSourceException('Error al insertar campana', originalError: e);
    }
  }

  Future<void> updateCampana(CampanaDTO campana) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        AppConstants.tableCampanas,
        campana.toMap(),
        where: 'id = ?',
        whereArgs: [campana.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _databaseHelper.insertSyncLogEntry({
        'id': const Uuid().v4(),
        'doctor_id': campana.creadoPor,
        'tabla_afectada': AppConstants.tableCampanas,
        'registro_id': campana.id,
        'operacion': 'UPDATE',
        'fecha_local': DateTime.now().toIso8601String(),
        'sincronizado': 0,
        'fecha_sync': null,
        'intentos': 0,
      });
    } on DatabaseException catch (e) {
      debugPrint('[DataSource] updateCampana error: $e');
      throw DataSourceException('Error al actualizar campana', originalError: e);
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
      debugPrint('[DataSource] getCampanasByDoctor error: $e');
      throw DataSourceException('Error al obtener campanas', originalError: e);
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
      debugPrint('[DataSource] checkDuplicate error: $e -- empresa=$nombreEmpresa lugar=$lugar');
      throw DataSourceException('Error al verificar duplicado', originalError: e);
    }
  }

  Future<void> insertCampanaSilent(CampanaDTO campana) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        AppConstants.tableCampanas,
        campana.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      debugPrint('[DataSource] insertCampanaSilent error: $e');
      throw DataSourceException('Error al cachear campana', originalError: e);
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
      );
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al asignar doctor a campana', originalError: e);
    }
  }

  Future<bool> assignDoctorExists(String campanaId) async {
    try {
      final db = await _databaseHelper.database;
      final existing = await db.query(
        AppConstants.tableDoctorCampana,
        where: 'campana_id = ?',
        whereArgs: [campanaId],
        limit: 1,
      );
      return existing.isNotEmpty;
    } on DatabaseException catch (e) {
      debugPrint('[DataSource] assignDoctorExists error: $e');
      return false;
    }
  }

  Future<List<DoctorProgressDTO>> getCampanaProgress(String campanaId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT dc.doctor_id, d.nombre as doctor_nombre, COUNT(p.id) as total_pacientes
        FROM ${AppConstants.tableDoctorCampana} dc
        INNER JOIN ${AppConstants.tableDoctores} d ON dc.doctor_id = d.id
        LEFT JOIN ${AppConstants.tableDependencias} dep ON dep.campana_id = dc.campana_id
        LEFT JOIN ${AppConstants.tablePacientes} p
          ON p.dependencia_id = dep.id AND p.doctor_id = dc.doctor_id
        WHERE dc.campana_id = ?
        GROUP BY dc.doctor_id, d.nombre
        ''',
        [campanaId],
      );
      return maps.map((map) => DoctorProgressDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException(
        'Error al obtener progreso de campana',
        originalError: e,
      );
    }
  }

  Future<void> insertEmpresa(Map<String, dynamic> empresaMap) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        AppConstants.tableEmpresas,
        empresaMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      debugPrint('[DataSource] insertEmpresa error: $e -- map: $empresaMap');
      throw DataSourceException('Error al insertar empresa', originalError: e);
    }
  }

  Future<List<UserDTO>> getAvailableDoctors(String campanaId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT *
        FROM ${AppConstants.tableDoctores}
        WHERE rol = 'USER' AND activo = 1
          AND id NOT IN (
            SELECT doctor_id
            FROM ${AppConstants.tableDoctorCampana}
            WHERE campana_id = ?
          )
        ORDER BY nombre ASC
        ''',
        [campanaId],
      );
      return maps.map((map) => UserDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException(
        'Error al obtener doctores disponibles',
        originalError: e,
      );
    }
  }
}
