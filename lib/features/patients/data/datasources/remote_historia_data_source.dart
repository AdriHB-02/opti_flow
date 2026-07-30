import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../models/historia_clinica_dto.dart';

class RemoteHistoriaDataSource {
  final SupabaseClient _supabaseClient;

  RemoteHistoriaDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  static const String _tableName = 'historias_clinicas';

  Future<void> upsert(HistoriaClinicaDTO historia) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw DataSourceException('Usuario no autenticado');
      }
      if (historia.doctorId != currentUser.id) {
        throw DataSourceException(
          'No autorizado: doctor_id no coincide con usuario actual',
        );
      }
      final data = _toSupabaseMap(historia);
      await _supabaseClient.from(_tableName).upsert(data);
    } on PostgrestException catch (e) {
      debugPrint('[RemoteHistoriaDataSource] upsert error: ${e.message}');
      throw DataSourceException(
        'Error al sincronizar historia clínica en remoto',
        originalError: e,
      );
    } on DataSourceException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('[RemoteHistoriaDataSource] upsert unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al sincronizar historia clínica',
        originalError: e,
      );
    }
  }

  Future<List<HistoriaClinicaDTO>> getByPacienteId(String pacienteId) async {
    try {
      final response = await _supabaseClient
        .from(_tableName)
        .select()
        .eq('paciente_id', pacienteId)
        .order('fecha_atencion', ascending: false);

      final List<HistoriaClinicaDTO> historias = [];
      for (final row in response) {
        historias.add(HistoriaClinicaDTO.fromMap(row));
      }
      return historias;
    } on PostgrestException catch (e) {
      debugPrint('[RemoteHistoriaDataSource] getByPacienteId error: ${e.message}');
      throw DataSourceException(
        'Error al obtener historias clínicas del paciente remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteHistoriaDataSource] getByPacienteId unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener historias clínicas del paciente remoto',
        originalError: e,
      );
    }
  }

  Future<List<HistoriaClinicaDTO>> getByCampanaId(String campanaId) async {
    try {
      final response = await _supabaseClient
        .from(_tableName)
        .select()
        .eq('campana_id', campanaId)
        .order('fecha_atencion', ascending: false);

      final List<HistoriaClinicaDTO> historias = [];
      for (final row in response) {
        historias.add(HistoriaClinicaDTO.fromMap(row));
      }
      return historias;
    } on PostgrestException catch (e) {
      debugPrint('[RemoteHistoriaDataSource] getByCampanaId error: \${e.message}');
      throw DataSourceException(
        'Error al obtener historias clínicas por campaña remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteHistoriaDataSource] getByCampanaId unexpected error: \$e');
      throw DataSourceException(
        'Error inesperado al obtener historias clínicas por campaña remoto',
        originalError: e,
      );
    }
  }

  Map<String, dynamic> _toSupabaseMap(HistoriaClinicaDTO historia) {
    return {
      'id': historia.id,
      'paciente_id': historia.pacienteId,
      'campana_id': historia.campanaId,
      'diagnostico_texto': historia.diagnosticoTexto,
      'imagen_url': historia.imagenUrl,
      'latitud': historia.latitud,
      'longitud': historia.longitud,
      'fecha_atencion': historia.fechaAtencion.toIso8601String(),
      'doctor_id': historia.doctorId,
      'historia_anterior_id': historia.historiaAnteriorId,
      'sincronizado': historia.sincronizado ? 1 : 0,
      'created_at': historia.createdAt.toIso8601String(),
    };
  }
}
