import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sync_status.dart';
import '../../domain/services/connectivity_service.dart';
import '../../domain/services/i_sync_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final ISyncService _syncService;
  final ConnectivityService _connectivityService;

  StreamSubscription<SyncStatus>? _statusSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  SyncBloc({
    required ISyncService syncService,
    required ConnectivityService connectivityService,
  })  : _syncService = syncService,
        _connectivityService = connectivityService,
        super(const SyncInitial()) {
    on<SyncRequested>(_onSyncRequested);
    on<SyncStatusChanged>(_onSyncStatusChanged);
    on<SyncManualTrigger>(_onSyncManualTrigger);

    _startListening();
  }

  void _startListening() {
    _statusSubscription = _syncService.status.listen((status) {
      add(SyncStatusChanged(isOnline: status != SyncStatus.offline));
    });

    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        add(const SyncManualTrigger());
      }
    });

    _connectivityService.init();
  }

  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    await _syncService.syncPendingRecords();
  }

  Future<void> _onSyncStatusChanged(
    SyncStatusChanged event,
    Emitter<SyncState> emit,
  ) async {
    if (!event.isOnline) {
      emit(const SyncOffline());
      return;
    }

    final online = await _syncService.isOnline();
    emit(online ? const SyncSynced() : const SyncOffline());
  }

  Future<void> _onSyncManualTrigger(
    SyncManualTrigger event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncSyncing());
    await _syncService.syncPendingRecords();
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    return super.close();
  }
}
