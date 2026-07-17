import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sync_log_entity.dart';

abstract class ISyncRepository {
  Future<Either<Failure, List<SyncLogEntity>>> getPendingRecords();

  Future<Either<Failure, void>> markAsSynced(String syncLogId);

  Future<Either<Failure, SyncLogEntity>> insertSyncLog(SyncLogEntity syncLog);

  Future<Either<Failure, void>> incrementIntentos(String syncLogId);

  Future<Either<Failure, Map<String, dynamic>?>> getRecordById(
    String tabla,
    String registroId,
  );
}
