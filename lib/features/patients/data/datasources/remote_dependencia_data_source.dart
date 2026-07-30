import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../models/dependencia_dto.dart';

class RemoteDependenciaDataSource {
  final SupabaseClient _supabaseClient;

  RemoteDependenciaDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  static const String _tableName = 'dependencias';

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
