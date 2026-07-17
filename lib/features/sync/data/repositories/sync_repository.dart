import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/sync_log_entity.dart';
import '../../domain/repositories/i_sync_repository.dart';
import '../models/sync_log_dto.dart';

class SyncRepository implements ISyncRepository {
  final DatabaseHelper _databaseHelper;

  SyncRepository({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  @override
  Future<Either<Failure, List<SyncLogEntity>>> getPendingRecords() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        AppConstants.tableSyncLog,
        where: 'sincronizado = ? AND intentos < ?',
        whereArgs: [0, AppConstants.maxSyncRetries + 1],
        orderBy: 'fecha_local ASC',
      );
      final entities = maps
          .map((map) => SyncLogDTO.fromMap(map).toEntity())
          .toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      debugPrint('[SyncRepo] getPendingRecords error: $e');
      return const Left(CacheFailure('Error al obtener registros pendientes'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String syncLogId) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        AppConstants.tableSyncLog,
        {
          'sincronizado': 1,
          'fecha_sync': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [syncLogId],
      );
      return const Right(null);
    } on DatabaseException catch (e) {
      debugPrint('[SyncRepo] markAsSynced error: $e');
      return const Left(CacheFailure('Error al marcar registro como sincronizado'));
    }
  }

  @override
  Future<Either<Failure, SyncLogEntity>> insertSyncLog(
    SyncLogEntity syncLog,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final dto = SyncLogDTO.fromEntity(syncLog);
      await db.insert(
        AppConstants.tableSyncLog,
        dto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Right(syncLog);
    } on DatabaseException catch (e) {
      debugPrint('[SyncRepo] insertSyncLog error: $e');
      return const Left(CacheFailure('Error al insertar sync log'));
    }
  }

  @override
  Future<Either<Failure, void>> incrementIntentos(String syncLogId) async {
    try {
      final db = await _databaseHelper.database;
      await db.rawUpdate(
        '''
        UPDATE ${AppConstants.tableSyncLog}
        SET intentos = intentos + 1
        WHERE id = ?
        ''',
        [syncLogId],
      );
      return const Right(null);
    } on DatabaseException catch (e) {
      debugPrint('[SyncRepo] incrementIntentos error: $e');
      return const Left(CacheFailure('Error al incrementar intentos'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getRecordById(
    String tabla,
    String registroId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        tabla,
        where: 'id = ?',
        whereArgs: [registroId],
        limit: 1,
      );
      if (maps.isEmpty) return Right(null);
      return Right(maps.first);
    } on DatabaseException catch (e) {
      debugPrint('[SyncRepo] getRecordById error: $e');
      return const Left(CacheFailure('Error al obtener registro'));
    }
  }
}
