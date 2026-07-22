import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/data_source_exception.dart';
import '../models/historia_clinica_dto.dart';

class LocalHistoriaDataSource {
  final DatabaseHelper _databaseHelper;

  LocalHistoriaDataSource({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  Future<void> insertHistoria(HistoriaClinicaDTO historia) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        AppConstants.tableHistoriasClinicas,
        historia.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _databaseHelper.insertSyncLogEntry({
        'id': const Uuid().v4(),
        'doctor_id': historia.doctorId,
        'tabla_afectada': AppConstants.tableHistoriasClinicas,
        'registro_id': historia.id,
        'operacion': 'INSERT',
        'fecha_local': DateTime.now().toIso8601String(),
        'sincronizado': 0,
        'fecha_sync': null,
        'intentos': 0,
      });
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al insertar historia clinica', originalError: e);
    }
  }

  Future<void> updateHistoria(HistoriaClinicaDTO historia) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        AppConstants.tableHistoriasClinicas,
        historia.toMap(),
        where: 'id = ?',
        whereArgs: [historia.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _databaseHelper.insertSyncLogEntry({
        'id': const Uuid().v4(),
        'doctor_id': historia.doctorId,
        'tabla_afectada': AppConstants.tableHistoriasClinicas,
        'registro_id': historia.id,
        'operacion': 'UPDATE',
        'fecha_local': DateTime.now().toIso8601String(),
        'sincronizado': 0,
        'fecha_sync': null,
        'intentos': 0,
      });
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al actualizar historia clinica', originalError: e);
    }
  }

  Future<List<HistoriaClinicaDTO>> getByPaciente(
    String pacienteId,
    String doctorId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tableHistoriasClinicas,
        where: 'paciente_id = ? AND doctor_id = ?',
        whereArgs: [pacienteId, doctorId],
        orderBy: 'fecha_atencion DESC',
      );
      return maps.map((map) => HistoriaClinicaDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al obtener historias clinicas', originalError: e);
    }
  }

  Future<HistoriaClinicaDTO?> getAnterior(String pacienteId, String campanaId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tableHistoriasClinicas,
        where: 'paciente_id = ? AND campana_id = ?',
        whereArgs: [pacienteId, campanaId],
        orderBy: 'fecha_atencion DESC',
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return HistoriaClinicaDTO.fromMap(maps.first);
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al obtener historia anterior', originalError: e);
    }
  }

  Future<List<HistoriaClinicaDTO>> getByCampana(String campanaId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tableHistoriasClinicas,
        where: 'campana_id = ?',
        whereArgs: [campanaId],
        orderBy: 'fecha_atencion DESC',
      );
      return maps.map((map) => HistoriaClinicaDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException(
        'Error al obtener historias clínicas por campaña',
        originalError: e,
      );
    }
  }
}
