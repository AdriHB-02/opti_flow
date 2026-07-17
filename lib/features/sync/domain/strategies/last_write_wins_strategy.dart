import 'i_sync_strategy.dart';

class LastWriteWinsStrategy implements ISyncStrategy {
  @override
  Map<String, dynamic> resolveConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localUpdatedAt = _parseDateTime(local['updated_at']);
    final remoteUpdatedAt = _parseDateTime(remote['updated_at']);

    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return local;
    }
    return remote;
  }

  DateTime _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
