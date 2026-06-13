import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
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
    } on DatabaseException catch (e) {
      throw Exception('Error al insertar paciente: $e');
    }
  }

  Future<List<PatientDTO>> getPatients(String dependenciaId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tablePacientes,
        where: 'dependencia_id = ?',
        whereArgs: [dependenciaId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => PatientDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw Exception('Error al obtener pacientes: $e');
    }
  }

  Future<List<PatientDTO>> searchByName(String name, String dependenciaId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tablePacientes,
        where: 'dependencia_id = ? AND nombre_completo LIKE ?',
        whereArgs: [dependenciaId, '%$name%'],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => PatientDTO.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw Exception('Error al buscar pacientes: $e');
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
      throw Exception('Error al obtener paciente por id: $e');
    }
  }
}
