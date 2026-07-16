import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';

class RemoteAuthDataSource {
  final SupabaseClient _client;

  RemoteAuthDataSource({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = authResponse.user;
    if (user == null) {
      throw Exception('Error de autenticación: usuario no encontrado');
    }
    final data = await _client
        .from(AppConstants.tableDoctores)
        .select()
        .eq('id', user.id)
        .single();
    return data;
  }

  Future<Map<String, dynamic>> loginBiometrico() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('No hay sesión activa');
    }
    final data = await _client
        .from(AppConstants.tableDoctores)
        .select()
        .eq('id', session.user.id)
        .single();
    return data;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<List<Map<String, dynamic>>> getAllDoctors({
    String? rol,
    String? empresaNombre,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    var query = _client.from(AppConstants.tableDoctores).select();

    if (rol != null && rol.isNotEmpty) {
      query = query.eq('rol', rol);
    }

    if (fechaDesde != null) {
      query = query.gte('created_at', fechaDesde.toIso8601String());
    }

    if (fechaHasta != null) {
      query = query.lte('created_at', fechaHasta.toIso8601String());
    }

    if (empresaNombre != null && empresaNombre.isNotEmpty) {
      final campanasResponse = await _client
          .from(AppConstants.tableCampanas)
          .select('id')
          .eq('nombre_empresa', empresaNombre);

      if (campanasResponse.isNotEmpty) {
        final campanaIds =
            campanasResponse.map((c) => c['id'] as String).toList();

        final doctorCampanasResponse = await _client
            .from(AppConstants.tableDoctorCampana)
            .select('doctor_id')
            .inFilter('campana_id', campanaIds);

        if (doctorCampanasResponse.isNotEmpty) {
          final doctorIds = doctorCampanasResponse
              .map((dc) => dc['doctor_id'] as String)
              .toList();
          query = query.inFilter('id', doctorIds);
        } else {
          return [];
        }
      } else {
        return [];
      }
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteDoctorAccount(String doctorId) async {
    await _client
        .from(AppConstants.tableDoctorCampana)
        .delete()
        .eq('doctor_id', doctorId);

    await _client
        .from(AppConstants.tablePacientes)
        .delete()
        .eq('doctor_id', doctorId);

    await _client
        .from(AppConstants.tableHistoriasClinicas)
        .delete()
        .eq('doctor_id', doctorId);

    await _client
        .from(AppConstants.tableDependencias)
        .delete()
        .eq('doctor_id', doctorId);

    await _client
        .from(AppConstants.tableDoctores)
        .delete()
        .eq('id', doctorId);

    await _client.auth.admin.deleteUser(doctorId);
  }

  Future<List<Map<String, dynamic>>> getPacientesPorMes() async {
    final response = await _client
        .from(AppConstants.tablePacientes)
        .select('created_at');

    final now = DateTime.now();
    final Map<String, int> counts = {};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      counts[key] = 0;
    }

    for (final row in response) {
      final fecha = DateTime.parse(row['created_at'] as String);
      final key =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }

    return counts.entries
        .map((e) => {'mes': e.key, 'cantidad': e.value})
        .toList();
  }

  Future<Map<String, int>> getGlobalStats() async {
    final campanasResponse = await _client
        .from(AppConstants.tableCampanas)
        .select('id')
        .eq('estado', 'ACTIVA');

    final pacientesResponse =
        await _client.from(AppConstants.tablePacientes).select('id');

    final doctoresResponse = await _client
        .from(AppConstants.tableDoctores)
        .select('id')
        .eq('activo', true);

    return {
      'campanasActivas': campanasResponse.length,
      'totalPacientes': pacientesResponse.length,
      'doctoresActivos': doctoresResponse.length,
    };
  }
}
