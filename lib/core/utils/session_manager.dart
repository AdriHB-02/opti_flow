import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _key = 'auth_session';
  static const _storage = FlutterSecureStorage();

  static Future<void> save({
    required String id,
    required String nombre,
    required String email,
    required String rol,
    required bool activo,
  }) async {
    await _storage.write(key: _key, value: jsonEncode({
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'activo': activo ? 1 : 0,
    }));
  }

  static Future<Map<String, dynamic>?> load() async {
    final data = await _storage.read(key: _key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }

  static Future<bool> isAdmin() async {
    final session = await load();
    return session?['rol'] == 'ADMIN';
  }

  static Future<String?> currentUserId() async {
    final session = await load();
    return session?['id'] as String?;
  }
}
