import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote_auth_data_source.dart';
import '../factories/user_factory.dart';

class AuthRepository implements IAuthRepository {
  final RemoteAuthDataSource _remoteDataSource;
  final DatabaseHelper _databaseHelper;

  AuthRepository({
    required RemoteAuthDataSource remoteDataSource,
    required DatabaseHelper databaseHelper,
  })  : _remoteDataSource = remoteDataSource,
        _databaseHelper = databaseHelper;

  Future<void> _upsertDoctorLocal(Map<String, dynamic> data) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().toIso8601String();
      await db.insert(
        AppConstants.tableDoctores,
        {
          'id': data['id'],
          'nombre': data['nombre'] ?? '',
          'email': data['email'] ?? '',
          'rol': data['rol'] ?? 'USER',
          'dependencia_local_id': data['dependencia_local_id'],
          'activo': data['activo'] ?? 1,
          'created_at': data['created_at'] ?? now,
          'updated_at': data['updated_at'] ?? now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[AuthRepo] _upsertDoctorLocal error: $e');
    }
  }

  Future<void> _syncAllDoctorsToLocal() async {
    try {
      final maps = await _remoteDataSource.getAllDoctors();
      final db = await _databaseHelper.database;
      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final doc in maps) {
          batch.insert(
            AppConstants.tableDoctores,
            {
              'id': doc['id'],
              'nombre': doc['nombre'] ?? '',
              'email': doc['email'] ?? '',
              'rol': doc['rol'] ?? 'USER',
              'dependencia_local_id': doc['dependencia_local_id'],
              'activo': doc['activo'] ?? 1,
              'created_at': doc['created_at'] ?? now,
              'updated_at': doc['updated_at'] ?? now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      debugPrint('[AuthRepo] Synced ${maps.length} doctors to local DB');
    } catch (e) {
      debugPrint('[AuthRepo] _syncAllDoctorsToLocal error: $e');
    }
  }

  Future<void> _syncDependenciasToLocal(String doctorId) async {
    try {
      final maps = await _remoteDataSource.getDependenciasByDoctor(doctorId);
      if (maps.isEmpty) return;
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final dep in maps) {
          batch.insert(
            AppConstants.tableDependencias,
            {
              'id': dep['id'],
              'tipo': dep['tipo'] ?? 'LOCAL',
              'campana_id': dep['campana_id'],
              'doctor_id': dep['doctor_id'],
              'nombre': dep['nombre'] ?? '',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      debugPrint('[AuthRepo] Synced ${maps.length} dependencias to local DB');
    } catch (e) {
      debugPrint('[AuthRepo] _syncDependenciasToLocal error: $e');
    }
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    final data = await _remoteDataSource.login(email, password);
    await _upsertDoctorLocal(data);
    await _syncAllDoctorsToLocal();
    await _syncDependenciasToLocal(data['id'] as String);
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario: $e');
    }
  }

  @override
  Future<UserEntity> loginBiometrico() async {
    final data = await _remoteDataSource.loginBiometrico();
    await _upsertDoctorLocal(data);
    await _syncAllDoctorsToLocal();
    await _syncDependenciasToLocal(data['id'] as String);
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario: $e');
    }
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    final data = await _remoteDataSource.loginWithGoogle();
    await _upsertDoctorLocal(data);
    await _syncAllDoctorsToLocal();
    await _syncDependenciasToLocal(data['id'] as String);
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario de Google: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
  }

  @override
  Future<void> recuperarPassword(String email) async {
    await _remoteDataSource.resetPassword(email);
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllDoctors({
    String? rol,
    String? empresaNombre,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      final maps = await _remoteDataSource.getAllDoctors(
        rol: rol,
        empresaNombre: empresaNombre,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      final doctors = maps.map((map) => UserFactory.fromMap(map)).toList();
      return Right(doctors);
    } catch (e) {
      debugPrint('[AuthRepo] getAllDoctors error: $e');
      return const Left(ServerFailure('Error al obtener el listado de doctores'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDoctorAccount(String doctorId) async {
    try {
      await _remoteDataSource.deleteDoctorAccount(doctorId);
      return const Right(null);
    } catch (e) {
      debugPrint('[AuthRepo] deleteDoctorAccount error: $e');
      return const Left(ServerFailure('Error al eliminar la cuenta del doctor'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPacientesPorMes() async {
    try {
      final data = await _remoteDataSource.getPacientesPorMes();
      return Right(data);
    } catch (e) {
      debugPrint('[AuthRepo] getPacientesPorMes error: $e');
      return const Left(ServerFailure('Error al obtener estadísticas de pacientes'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getGlobalStats() async {
    try {
      final stats = await _remoteDataSource.getGlobalStats();
      return Right(stats);
    } catch (e) {
      debugPrint('[AuthRepo] getGlobalStats error: $e');
      return const Left(ServerFailure('Error al obtener las estadísticas globales'));
    }
  }
}
