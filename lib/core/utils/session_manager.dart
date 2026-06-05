import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _key = 'auth_session';

  static Future<void> save({
    required String id,
    required String nombre,
    required String email,
    required String rol,
    required bool activo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'activo': activo ? 1 : 0,
    }));
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
