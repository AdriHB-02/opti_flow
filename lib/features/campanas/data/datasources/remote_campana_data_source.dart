import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../models/campana_dto.dart';

class RemoteCampanaDataSource {
  final SupabaseClient _supabaseClient;

  RemoteCampanaDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  static const String _tableName = 'campanas';
  static const String _empresasTable = 'empresas';

  Future<void> upsertEmpresa(Map<String, dynamic> empresaMap) async {
    try {
      await _supabaseClient.from(_empresasTable).upsert(empresaMap);
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] upsertEmpresa error: ${e.message}');
      throw DataSourceException(
        'Error al sincronizar empresa en remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteCampanaDataSource] upsertEmpresa unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al sincronizar empresa',
        originalError: e,
      );
    }
  }

  Future<void> upsert(CampanaDTO campana) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw DataSourceException('Usuario no autenticado');
      }
      if (campana.creadoPor != currentUser.id) {
        throw DataSourceException(
          'No autorizado: creado_por no coincide con usuario actual',
        );
      }
      final data = _toSupabaseMap(campana);
      await _supabaseClient.from(_tableName).upsert(data);
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] upsert error: ${e.message}');
      throw DataSourceException(
        'Error al sincronizar campana en remoto',
        originalError: e,
      );
    } on DataSourceException {
      rethrow;
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

  Future<List<Map<String, dynamic>>> getCampanaProgressByCampanaId(
    String campanaId,
  ) async {
    try {
      // Get doctors and patient counts from historias_clinicas grouped by doctor
      final historias = await _supabaseClient
        .from('historias_clinicas')
        .select('doctor_id, paciente_id')
        .eq('campana_id', campanaId);

      if (historias.isEmpty) return [];

      // Get unique doctor IDs and count distinct patients per doctor
      final doctorPatientCounts = <String, Set<String>>{};
      for (final h in historias) {
        final doctorId = h['doctor_id'] as String;
        final pacienteId = h['paciente_id'] as String;
        doctorPatientCounts.putIfAbsent(doctorId, () => <String>{});
        doctorPatientCounts[doctorId]!.add(pacienteId);
      }

      // Get doctor names
      final doctorIds = doctorPatientCounts.keys.toList();
      final doctoresData = await _supabaseClient
        .from('doctores')
        .select('id, nombre')
        .inFilter('id', doctorIds);

      final doctorNames = <String, String>{};
      for (final d in doctoresData) {
        doctorNames[d['id'] as String] = d['nombre'] as String;
      }

      // Build result
      return doctorPatientCounts.entries.map((e) {
        return {
          'doctor_id': e.key,
          'doctor_nombre': doctorNames[e.key] ?? 'Desconocido',
          'total_pacientes': e.value.length,
        };
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('[RemoteCampanaDataSource] getCampanaProgressByCampanaId error: \${e.message}');
      throw DataSourceException(
        'Error al obtener progreso de campaña remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemoteCampanaDataSource] getCampanaProgressByCampanaId unexpected error: \$e');
      throw DataSourceException(
        'Error inesperado al obtener progreso de campaña remoto',
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
