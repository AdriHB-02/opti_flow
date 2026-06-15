import 'package:sqflite/sqflite.dart';

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
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al insertar historia clínica', originalError: e);
    }
  }

  Future<List<HistoriaClinicaDTO>> getByPaciente(String pacienteId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tableHistoriasClinicas,
        where: 'paciente_id = ?',
        whereArgs: [pacienteId],
        orderBy: 'fecha_atencion DESC',
      );
      return maps.map((map) => HistoriaClinicaDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DataSourceException('Error al obtener historias clínicas', originalError: e);
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
}
