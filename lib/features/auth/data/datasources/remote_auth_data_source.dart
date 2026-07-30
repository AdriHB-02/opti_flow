import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
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

  Future<Map<String, dynamic>> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    unawaited(googleSignIn.initialize(
      clientId: AppConstants.googleIosClientId.isNotEmpty
          ? AppConstants.googleIosClientId
          : null,
      serverClientId: AppConstants.googleWebClientId.isNotEmpty
          ? AppConstants.googleWebClientId
          : null,
    ));

    final googleAccount = await googleSignIn.authenticate();
    final idToken = googleAccount.authentication.idToken;
    if (idToken == null) {
      throw Exception('No se obtuvo ID Token de Google');
    }

    final authResponse = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    final user = authResponse.user;
    if (user == null) {
      throw Exception('Error de autenticación con Google');
    }

    final existing = await _client
        .from(AppConstants.tableDoctores)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      final nombre = user.userMetadata?['full_name'] as String? ??
          user.email?.split('@').first ??
          'Usuario Google';
      await _client.from(AppConstants.tableDoctores).insert({
        'id': user.id,
        'nombre': nombre,
        'email': user.email,
        'rol': 'USER',
        'activo': 1,
        'password_hash': '',  // ← NUEVO: usuarios Google no tienen password local
      });
      return await _client
          .from(AppConstants.tableDoctores)
          .select()
          .eq('id', user.id)
          .single();
    }

    return existing;
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
        .from(AppConstants.tableHistoriasClinicas)
        .delete()
        .eq('doctor_id', doctorId);

    await _client
        .from(AppConstants.tablePacientes)
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
  }

  Future<List<Map<String, dynamic>>> getDependenciasByDoctor(String doctorId) async {
    final campanaRows = await _client
        .from(AppConstants.tableDoctorCampana)
        .select('campana_id')
        .eq('doctor_id', doctorId);
    final campanaIds =
        campanaRows.map((r) => r['campana_id'] as String).toList();

    final directas = await _client
        .from(AppConstants.tableDependencias)
        .select()
        .eq('doctor_id', doctorId);
    final result = List<Map<String, dynamic>>.from(directas);

    if (campanaIds.isNotEmpty) {
      final porCampana = await _client
          .from(AppConstants.tableDependencias)
          .select()
          .inFilter('campana_id', campanaIds);
      final existentes = result.map((r) => r['id'] as String).toSet();
      for (final row in porCampana) {
        if (!existentes.contains(row['id'] as String)) {
          result.add(row);
        }
      }
    }

    return result;
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
      final raw = row['created_at'] as String?;
      if (raw == null) continue;
      final fecha = DateTime.tryParse(raw);
      if (fecha == null) continue;
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
        .eq('activo', 1);

    return {
      'campanasActivas': campanasResponse.length,
      'totalPacientes': pacientesResponse.length,
      'doctoresActivos': doctoresResponse.length,
    };
  }
}
