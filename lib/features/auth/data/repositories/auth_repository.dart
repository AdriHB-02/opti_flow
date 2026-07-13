import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote_auth_data_source.dart';
import '../factories/user_factory.dart';

class AuthRepository implements IAuthRepository {
  final RemoteAuthDataSource _remoteDataSource;

  AuthRepository({required RemoteAuthDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<UserEntity> login(String email, String password) async {
    final data = await _remoteDataSource.login(email, password);
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario: $e');
    }
  }

  @override
  Future<UserEntity> loginBiometrico() async {
    final data = await _remoteDataSource.loginBiometrico();
    try {
      return UserFactory.fromMap(data);
    } catch (e) {
      throw Exception('Error al procesar datos de usuario: $e');
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
      return Left(ServerFailure('Error al obtener doctores: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDoctorAccount(String doctorId) async {
    try {
      await _remoteDataSource.deleteDoctorAccount(doctorId);
      return const Right(null);
    } catch (e) {
      debugPrint('[AuthRepo] deleteDoctorAccount error: $e');
      return Left(ServerFailure('Error al eliminar cuenta del doctor: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getGlobalStats() async {
    try {
      final stats = await _remoteDataSource.getGlobalStats();
      return Right(stats);
    } catch (e) {
      debugPrint('[AuthRepo] getGlobalStats error: $e');
      return Left(ServerFailure('Error al obtener estadísticas: $e'));
    }
  }
}
