abstract class ISyncStrategy {
  Map<String, dynamic> resolveConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  );
}
