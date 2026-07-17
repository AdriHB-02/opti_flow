import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../models/campana_dto.dart';

class RemoteCampanaDataSource {
  final SupabaseClient _supabaseClient;

  RemoteCampanaDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  static const String _tableName = 'campanas';

  Future<void> upsert(CampanaDTO campana) async {
    try {
      final data = _toSupabaseMap(campana);
      await _supabaseClient.from(_tableName).upsert(data);
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] upsert error: ${e.message}');
      throw DataSourceException(
        'Error al sincronizar campana en remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteCampanaDataSource] upsert unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al sincronizar campana',
        originalError: e,
      );
    }
  }

  Future<List<CampanaDTO>> getAll() async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      final List<CampanaDTO> campanas = [];
      for (final row in response) {
        campanas.add(CampanaDTO.fromMap(row));
      }
      return campanas;
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] getAll error: ${e.message}');
      throw DataSourceException(
        'Error al obtener campañas remotas',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteCampanaDataSource] getAll unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener campañas remotas',
        originalError: e,
      );
    }
  }

  Future<List<CampanaDTO>> getByDoctorId(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('creado_por', doctorId)
          .order('created_at', ascending: false);

      final List<CampanaDTO> campanas = [];
      for (final row in response) {
        campanas.add(CampanaDTO.fromMap(row));
      }
      return campanas;
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] getByDoctorId error: ${e.message}');
      throw DataSourceException(
        'Error al obtener campañas por doctor remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteCampanaDataSource] getByDoctorId unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener campañas por doctor remoto',
        originalError: e,
      );
    }
  }

  Future<List<CampanaDTO>> getByEmpresa(String nombreEmpresa, String lugar) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('nombre_empresa', nombreEmpresa)
          .eq('lugar', lugar)
          .order('created_at', ascending: false);

      final List<CampanaDTO> campanas = [];
      for (final row in response) {
        campanas.add(CampanaDTO.fromMap(row));
      }
      return campanas;
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] getByEmpresa error: ${e.message}');
      throw DataSourceException(
        'Error al obtener campañas por empresa remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteCampanaDataSource] getByEmpresa unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener campañas por empresa remoto',
        originalError: e,
      );
    }
  }

  Future<CampanaDTO?> getById(String id) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return CampanaDTO.fromMap(response);
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] getById error: ${e.message}');
      throw DataSourceException(
        'Error al obtener campaña por id remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteCampanaDataSource] getById unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener campaña por id remoto',
        originalError: e,
      );
    }
  }

  Map<String, dynamic> _toSupabaseMap(CampanaDTO campana) {
    return {
      'id': campana.id,
      'empresa_id': campana.empresaId,
      'nombre_empresa': campana.nombreEmpresa,
      'lugar': campana.lugar,
      'fecha_inicio': campana.fechaInicio.toIso8601String(),
      'fecha_fin': campana.fechaFin.toIso8601String(),
      'creado_por': campana.creadoPor,
      'estado': campana.estado.name.toUpperCase(),
      'created_at': campana.createdAt.toIso8601String(),
    };
  }
}
