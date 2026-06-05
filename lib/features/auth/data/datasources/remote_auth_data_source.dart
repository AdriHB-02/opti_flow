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
    final userId = authResponse.user!.id;
    final data = await _client
        .from(AppConstants.tableDoctores)
        .select()
        .eq('id', userId)
        .single();
    return data;
  }

  Future<Map<String, dynamic>> loginBiometrico() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('No hay sesión activa');
    }
    final userId = session.user.id;
    final data = await _client
        .from(AppConstants.tableDoctores)
        .select()
        .eq('id', userId)
        .single();
    return data;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
