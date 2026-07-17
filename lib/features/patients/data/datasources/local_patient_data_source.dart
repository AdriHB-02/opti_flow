import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/data_source_exception.dart';
import '../models/patient_dto.dart';

class LocalPatientDataSource {
  final DatabaseHelper _databaseHelper;

  LocalPatientDataSource({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  Future<void> insertPatient(PatientDTO patient) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        AppConstants.tablePacientes,
        patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _databaseHelper.insertSyncLogEntry({
        'id': const Uuid().v4(),
        'doctor_id': patient.doctorId,
        'tabla_afectada': AppConstants.tablePacientes,
        'registro_id': patient.id,
        'operacion': 'INSERT',
        'fecha_local': DateTime.now().toIso8601String(),
        'sincronizado': 0,
        'fecha_sync': null,
        'intentos': 0,
      });
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al insertar paciente', originalError: e);
    }
  }

  Future<void> updatePatient(PatientDTO patient) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        AppConstants.tablePacientes,
        patient.toMap(),
        where: 'id = ?',
        whereArgs: [patient.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _databaseHelper.insertSyncLogEntry({
        'id': const Uuid().v4(),
        'doctor_id': patient.doctorId,
        'tabla_afectada': AppConstants.tablePacientes,
        'registro_id': patient.id,
        'operacion': 'UPDATE',
        'fecha_local': DateTime.now().toIso8601String(),
        'sincronizado': 0,
        'fecha_sync': null,
        'intentos': 0,
      });
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al actualizar paciente', originalError: e);
    }
  }

  Future<List<PatientDTO>> getPatients(
    String dependenciaId,
    String doctorId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tablePacientes,
        where: 'dependencia_id = ? AND doctor_id = ?',
        whereArgs: [dependenciaId, doctorId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => PatientDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al obtener pacientes', originalError: e);
    }
  }

  Future<List<PatientDTO>> searchByName(
    String name,
    String dependenciaId,
    String doctorId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tablePacientes,
        where:
            'dependencia_id = ? AND doctor_id = ? AND nombre_completo LIKE ?',
        whereArgs: [dependenciaId, doctorId, '%$name%'],
        orderBy: 'created_at DESC',
        limit: 50,
      );
      return maps.map((map) => PatientDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al buscar pacientes', originalError: e);
    }
  }

  Future<PatientDTO?> getPatientById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tablePacientes,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return PatientDTO.fromMap(maps.first);
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al obtener paciente por id', originalError: e);
    }
  }

  Future<List<PatientDTO>> getPatientsByCampanaId(String campanaId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT p.*
        FROM ${AppConstants.tablePacientes} p
        INNER JOIN ${AppConstants.tableDependencias} dep
          ON p.dependencia_id = dep.id
        WHERE dep.campana_id = ?
        ORDER BY p.created_at DESC
        ''',
        [campanaId],
      );
      return maps.map((map) => PatientDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException(
        'Error al obtener pacientes por campana',
        originalError: e,
      );
    }
  }
}
