import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_source_exception.dart';
import '../models/patient_dto.dart';

class RemotePatientDataSource {
  final SupabaseClient _supabaseClient;

  RemotePatientDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  static const String _tableName = 'pacientes';

  Future<void> upsert(PatientDTO patient) async {
    try {
      final data = _toSupabaseMap(patient);
      await _supabaseClient.from(_tableName).upsert(data);
    } on PostgrestException catch (e) {
      debugPrint('[RemotePatientDataSource] upsert error: ${e.message}');
      throw DataSourceException(
        'Error al sincronizar paciente en remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemotePatientDataSource] upsert unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al sincronizar paciente',
        originalError: e,
      );
    }
  }

  Future<List<PatientDTO>> getAll() async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      final List<PatientDTO> patients = [];
      for (final row in response) {
        patients.add(PatientDTO.fromMap(row));
      }
      return patients;
    } on PostgrestException catch (e) {
      debugPrint('[RemotePatientDataSource] getAll error: ${e.message}');
      throw DataSourceException(
        'Error al obtener pacientes remotos',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemotePatientDataSource] getAll unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener pacientes remotos',
        originalError: e,
      );
    }
  }

  Future<List<PatientDTO>> getByDoctorId(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      final List<PatientDTO> patients = [];
      for (final row in response) {
        patients.add(PatientDTO.fromMap(row));
      }
      return patients;
    } on PostgrestException catch (e) {
      debugPrint('[RemotePatientDataSource] getByDoctorId error: ${e.message}');
      throw DataSourceException(
        'Error al obtener pacientes por doctor remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemotePatientDataSource] getByDoctorId unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener pacientes por doctor remoto',
        originalError: e,
      );
    }
  }

  Future<List<PatientDTO>> getByDependenciaId(String dependenciaId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('dependencia_id', dependenciaId)
          .order('created_at', ascending: false);

      final List<PatientDTO> patients = [];
      for (final row in response) {
        patients.add(PatientDTO.fromMap(row));
      }
      return patients;
    } on PostgrestException catch (e) {
      debugPrint('[RemotePatientDataSource] getByDependenciaId error: ${e.message}');
      throw DataSourceException(
        'Error al obtener pacientes por dependencia remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemotePatientDataSource] getByDependenciaId unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener pacientes por dependencia remoto',
        originalError: e,
      );
    }
  }

  Future<PatientDTO?> getById(String id) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return PatientDTO.fromMap(response);
    } on PostgrestException catch (e) {
      debugPrint('[RemotePatientDataSource] getById error: ${e.message}');
      throw DataSourceException(
        'Error al obtener paciente por id remoto',
        originalError: e,
      );
    } on Exception catch (e) {
      debugPrint('[RemotePatientDataSource] getById unexpected error: $e');
      throw DataSourceException(
        'Error inesperado al obtener paciente por id remoto',
        originalError: e,
      );
    }
  }

  Map<String, dynamic> _toSupabaseMap(PatientDTO patient) {
    return {
      'id': patient.id,
      'nombre_completo': patient.nombreCompleto,
      'dependencia_id': patient.dependenciaId,
      'doctor_id': patient.doctorId,
      'es_reconsulta': patient.esReconsulta,
      'created_at': patient.createdAt.toIso8601String(),
      'updated_at': patient.updatedAt.toIso8601String(),
    };
  }
}
