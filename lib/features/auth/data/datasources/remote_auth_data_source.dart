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
}
