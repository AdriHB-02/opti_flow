import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/sync_log_entity.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/i_sync_repository.dart';
import '../../domain/services/i_sync_service.dart';
import '../../domain/strategies/i_sync_strategy.dart';

class SyncService implements ISyncService {
  final ISyncRepository _syncRepository;
  final SupabaseClient _supabaseClient;
  final ISyncStrategy _syncStrategy;
  final InternetConnection _internetConnection;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  bool _isSyncing = false;

  SyncService({
    required ISyncRepository syncRepository,
    required SupabaseClient supabaseClient,
    required ISyncStrategy syncStrategy,
    InternetConnection? internetConnection,
  })  : _syncRepository = syncRepository,
        _supabaseClient = supabaseClient,
        _syncStrategy = syncStrategy,
        _internetConnection = internetConnection ?? InternetConnection();

  @override
  Stream<SyncStatus> get status => _statusController.stream;

  @override
  Future<bool> isOnline() async {
    return _internetConnection.hasInternetAccess;
  }

  @override
  Future<void> syncPendingRecords() async {
    if (_isSyncing) return;

    final online = await _internetConnection.hasInternetAccess;
    if (!online) {
      _statusController.add(SyncStatus.offline);
      return;
    }

    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final result = await _syncRepository.getPendingRecords();
      result.fold(
        (failure) {
          _statusController.add(SyncStatus.error);
          _isSyncing = false;
        },
        (pendingRecords) async {
          if (pendingRecords.isEmpty) {
            _statusController.add(SyncStatus.synced);
            _isSyncing = false;
            return;
          }

          bool hasError = false;

          for (final syncLog in pendingRecords) {
            final success = await _syncRecord(syncLog);
            if (!success) {
              hasError = true;
            }
          }

          _statusController.add(hasError ? SyncStatus.error : SyncStatus.synced);
          _isSyncing = false;
        },
      );
    } catch (e) {
      debugPrint('[SyncService] syncPendingRecords unexpected error: $e');
      _statusController.add(SyncStatus.error);
      _isSyncing = false;
    }
  }

  Future<bool> _syncRecord(SyncLogEntity syncLog) async {
    try {
      final recordResult = await _syncRepository.getRecordById(
        syncLog.tablaAfectada,
        syncLog.registroId,
      );

      return recordResult.fold(
        (failure) {
          _handleSyncFailure(syncLog);
          return false;
        },
        (recordData) async {
          if (recordData == null) {
            await _syncRepository.markAsSynced(syncLog.id);
            return true;
          }

          return await _upsertToSupabase(syncLog, recordData);
        },
      );
    } catch (e) {
      debugPrint('[SyncService] _syncRecord error: $e');
      _handleSyncFailure(syncLog);
      return false;
    }
  }

  Future<bool> _upsertToSupabase(
    SyncLogEntity syncLog,
    Map<String, dynamic> localData,
  ) async {
    try {
      final tableName = _mapLocalTableToSupabase(syncLog.tablaAfectada);

      final remoteResult = await _supabaseClient
          .from(tableName)
          .select()
          .eq('id', syncLog.registroId)
          .maybeSingle();

      Map<String, dynamic> dataToUpsert;

      if (remoteResult != null) {
        dataToUpsert = _syncStrategy.resolveConflict(localData, remoteResult);
      } else {
        dataToUpsert = _convertLocalToRemote(localData, syncLog.tablaAfectada);
      }

      await _supabaseClient.from(tableName).upsert(dataToUpsert);

      await _syncRepository.markAsSynced(syncLog.id);
      return true;
    } on Exception catch (e) {
      debugPrint('[SyncService] upsert error for ${syncLog.id}: $e');
      _handleSyncFailure(syncLog);
      return false;
    }
  }

  Future<void> _handleSyncFailure(SyncLogEntity syncLog) async {
    if (syncLog.intentos + 1 > AppConstants.maxSyncRetries) {
      debugPrint(
        '[SyncService] record ${syncLog.id} exceeded max retries '
        '(${syncLog.intentos + 1}/${AppConstants.maxSyncRetries}), skipping',
      );
      return;
    }
    await _syncRepository.incrementIntentos(syncLog.id);
  }

  String _mapLocalTableToSupabase(String localTable) {
    switch (localTable) {
      case AppConstants.tablePacientes:
        return 'pacientes';
      case AppConstants.tableHistoriasClinicas:
        return 'historias_clinicas';
      case AppConstants.tableCampanas:
        return 'campanas';
      case AppConstants.tableDoctores:
        return 'doctores';
      case AppConstants.tableEmpresas:
        return 'empresas';
      default:
        return localTable;
    }
  }

  Map<String, dynamic> _convertLocalToRemote(
    Map<String, dynamic> localData,
    String tabla,
  ) {
    final converted = Map<String, dynamic>.from(localData);

    switch (tabla) {
      case AppConstants.tablePacientes:
        converted['es_reconsulta'] = converted['es_reconsulta'] == 1;
        break;
      case AppConstants.tableHistoriasClinicas:
        converted['sincronizado'] = converted['sincronizado'] == 1;
        break;
    }

    return converted;
  }

  void dispose() {
    _statusController.close();
  }
}
