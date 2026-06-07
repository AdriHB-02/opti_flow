import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../utils/password_crypto.dart';

class AppSeed {
  static const _seedKey = 'optiflow_seed_doctores_done';

  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seedKey) == true) return;

    final serviceRoleKey = AppConstants.serviceRoleKey;

    if (serviceRoleKey.isEmpty) {
      print('[Seed] SUPABASE_SERVICE_ROLE_KEY no configurada — seed omitido');
      return;
    }

    try {
      final adminClient = SupabaseClient(
        AppConstants.supabaseUrl,
        serviceRoleKey,
      );

      final now = DateTime.now().toUtc().toIso8601String();

      final seedDoctors = [
        _DoctorSeed(
          nombre: 'Admin OptiFlow',
          email: 'admin@optiflow.com',
          password: 'Admin123!',
          rol: 'ADMIN',
        ),
        _DoctorSeed(
          nombre: 'Dr. Jefe',
          email: 'jefe@optiflow.com',
          password: 'Jefe123!',
          rol: 'JEFE',
        ),
        _DoctorSeed(
          nombre: 'Dr. Usuario',
          email: 'doctor@optiflow.com',
          password: 'Doctor123!',
          rol: 'USER',
        ),
      ];

      for (final doc in seedDoctors) {
        final existing = await adminClient
            .from(AppConstants.tableDoctores)
            .select('id')
            .eq('email', doc.email)
            .maybeSingle();

        if (existing != null) {
          print('[Seed] Ya existe: ${doc.email}');
          continue;
        }

        final authResponse = await adminClient.auth.admin.createUser(
          AdminUserAttributes(
            email: doc.email,
            password: doc.password,
            emailConfirm: true,
          ),
        );

        final userId = authResponse.user!.id;

        await adminClient.from(AppConstants.tableDoctores).insert({
          'id': userId,
          'nombre': doc.nombre,
          'email': doc.email,
          'password_hash': PasswordCrypto.encryptPassword(doc.password),
          'rol': doc.rol,
          'activo': 1,
          'created_at': now,
          'updated_at': now,
        });

        print('[Seed] Creado: ${doc.email} (${doc.rol}) — id: $userId');

        final confirm = await adminClient
            .from(AppConstants.tableDoctores)
            .select('id')
            .eq('id', userId)
            .maybeSingle();
        if (confirm == null) {
          print('[Seed] ⚠ No se pudo leer el registro creado — ¿RLS activo sin policies?');
        }
      }

      await prefs.setBool(_seedKey, true);
      print('[Seed] Seed completado exitosamente');
    } catch (e) {
      print('[Seed] Error no crítico: $e');
    }
  }
}

class _DoctorSeed {
  final String nombre;
  final String email;
  final String password;
  final String rol;

  const _DoctorSeed({
    required this.nombre,
    required this.email,
    required this.password,
    required this.rol,
  });
}
