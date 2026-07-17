import '../entities/sync_status.dart';

abstract class ISyncService {
  Stream<SyncStatus> get status;
  Future<void> syncPendingRecords();
  Future<bool> isOnline();
}
