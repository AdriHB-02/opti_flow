import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncRequested extends SyncEvent {
  const SyncRequested();
}

class SyncStatusChanged extends SyncEvent {
  final bool isOnline;

  const SyncStatusChanged({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}

class SyncManualTrigger extends SyncEvent {
  const SyncManualTrigger();
}
