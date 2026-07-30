import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../models/dependencia_dto.dart';

class RemoteDependenciaDataSource {
  final SupabaseClient _supabaseClient;

  RemoteDependenciaDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  static const String _tableName = 'dependencias';

  Future<List<DependenciaDTO>> getDependenciasByDoctor(String doctorId) async {
    try {
      final campanaRows = await _supabaseClient
          .from('doctor_campana')
          .select('campana_id')
          .eq('doctor_id', doctorId);
      final campanaIds =
          campanaRows.map((r) => r['campana_id'] as String).toList();

      final directas = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('doctor_id', doctorId);
      final result = List<Map<String, dynamic>>.from(directas);

      if (campanaIds.isNotEmpty) {
        final porCampana = await _supabaseClient
            .from(_tableName)
            .select()
            .inFilter('campana_id', campanaIds);
        final existentes = result.map((r) => r['id'] as String).toSet();
        for (final row in porCampana) {
          if (!existentes.contains(row['id'] as String)) {
            result.add(row);
          }
        }
      }

      return result.map((map) => DependenciaDTO.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      debugPrint('[RemoteDependenciaDataSource] getDependenciasByDoctor error: ${e.message}');
      throw DataSourceException(
        'Error al obtener dependencias remotas',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteDependenciaDataSource] getDependenciasByDoctor unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener dependencias remotas',
        originalError: e,
      );
    }
  }

  Future<void> upsert(DependenciaDTO dependencia) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw DataSourceException('Usuario no autenticado');
      }
      if (dependencia.doctorId != null && dependencia.doctorId != currentUser.id) {
        throw DataSourceException(
          'No autorizado: doctor_id no coincide con usuario actual',
        );
      }
      await _supabaseClient.from(_tableName).upsert(dependencia.toMap());
    } on PostgrestException catch (e) {
      debugPrint('[RemoteDependenciaDataSource] upsert error: ${e.message}');
      throw DataSourceException(
        'Error al sincronizar dependencia en remoto',
        originalError: e,
      );
    } on DataSourceException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('[RemoteDependenciaDataSource] upsert unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al sincronizar dependencia',
        originalError: e,
      );
    }
  }
}
