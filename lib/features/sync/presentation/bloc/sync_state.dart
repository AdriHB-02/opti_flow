import 'package:equatable/equatable.dart';

import '../../domain/entities/sync_status.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncSyncing extends SyncState {
  const SyncSyncing();
}

class SyncSynced extends SyncState {
  const SyncSynced();
}

class SyncOffline extends SyncState {
  const SyncOffline();
}

class SyncError extends SyncState {
  final String message;

  const SyncError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SyncStatusUpdated extends SyncState {
  final SyncStatus status;

  const SyncStatusUpdated({required this.status});

  @override
  List<Object?> get props => [status];
}
