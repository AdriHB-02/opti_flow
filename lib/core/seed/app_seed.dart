import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../utils/password_crypto.dart';

class AppSeed {
  static const _seedKey = 'optiflow_seed_doctores_done';

  static Future<void> run() async {
    debugPrint('[SEED] ====== INICIO ======');
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── FORCE: si SharedPreferences dice "done" pero la tabla está vacía, ignóralo ──
      final serviceRoleKey = AppConstants.serviceRoleKey;
      if (serviceRoleKey.isNotEmpty) {
        try {
          final checkClient = SupabaseClient(AppConstants.supabaseUrl, serviceRoleKey);
          final countResult = await checkClient
              .from(AppConstants.tableDoctores)
              .select('id')
              .count(CountOption.exact);
          final total = countResult.count;
          debugPrint('[SEED] doctores row count = $total');
        } catch (e) {
          debugPrint('[SEED] count query falló (esperado si tabla nueva): $e');
        }
      } else {
        debugPrint('[SEED] ⛔ serviceRoleKey vacía');
        return;
      }

      final alreadyRun = prefs.getBool(_seedKey);
      debugPrint('[SEED] SharedPreferences._seedKey = $alreadyRun');
      debugPrint('[SEED] Forzando re-ejecución — ignorando SharedPreferences');

      final url = AppConstants.supabaseUrl;
      final adminClient = SupabaseClient(url, serviceRoleKey);
      debugPrint('[SEED] SupabaseClient creado con url=$url');

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
        debugPrint('[SEED] --- Procesando: ${doc.email} ---');

        try {
          // ── 1. Verificar si ya existe en doctores ──
          final existing = await adminClient
              .from(AppConstants.tableDoctores)
              .select('id')
              .eq('email', doc.email)
              .maybeSingle();
          debugPrint('[SEED] existing en doctores = $existing');

          if (existing != null) {
            debugPrint('[SEED] Ya existe en doctores: ${doc.email}');
            continue;
          }

          // ── 2. Crear en Auth ──
          String userId;
          debugPrint('[SEED] createUser: ${doc.email}...');
          try {
            final authResponse = await adminClient.auth.admin.createUser(
              AdminUserAttributes(
                email: doc.email,
                password: doc.password,
                emailConfirm: true,
              ),
            );
            userId = authResponse.user!.id;
            debugPrint('[SEED] ✅ createUser OK: $userId');
          } catch (e) {
            debugPrint('[SEED] ⚠ createUser falló: $e');
            debugPrint('[SEED] Buscando usuario existente en Auth...');
            final users = await adminClient.auth.admin.listUsers();
            debugPrint('[SEED] Auth users encontrados: ${users.length}');
            for (final u in users) {
              debugPrint('[SEED]   Auth: ${u.email} / ${u.id}');
            }
            final u = users.firstWhere(
              (u) => u.email == doc.email,
              orElse: () => throw Exception('No existe en Auth: ${doc.email}'),
            );
            userId = u.id;
            debugPrint('[SEED] ✅ Auth recuperado: $userId');
          }

          // ── 3. Insert en doctores con HTTP directo para capturar respuesta real ──
          debugPrint('[SEED] === INSERTANDO EN DOCTORES VÍA HTTP DIRECTO ===');

          final body = {
            'id': userId,
            'nombre': doc.nombre,
            'email': doc.email,
            'password_hash': PasswordCrypto.encryptPassword(doc.password),
            'rol': doc.rol,
            'activo': 1,
            'created_at': now,
            'updated_at': now,
          };

          final insertUrl = Uri.parse('$url/rest/v1/doctores');
          debugPrint('[SEED] POST $insertUrl');

          final httpClient = http.Client();
          try {
            final httpResponse = await httpClient.post(
              insertUrl,
              headers: {
                'apikey': serviceRoleKey,
                'Authorization': 'Bearer $serviceRoleKey',
                'Content-Type': 'application/json',
                'Prefer': 'return=representation',
              },
              body: jsonEncode(body),
            );

            debugPrint('[SEED] HTTP status: ${httpResponse.statusCode}');
            debugPrint('[SEED] HTTP body: ${httpResponse.body}');
            debugPrint('[SEED] HTTP headers: ${httpResponse.headers}');

            if (httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299) {
              debugPrint('[SEED] ✅ INSERT HTTP OK');
            } else {
              debugPrint('[SEED] ⛔ INSERT HTTP ERROR: ${httpResponse.statusCode}');
              debugPrint('[SEED] Error body: ${httpResponse.body}');
            }
          } finally {
            httpClient.close();
          }

          // ── 4. Verificar ──
          final confirm = await adminClient
              .from(AppConstants.tableDoctores)
              .select('id')
              .eq('id', userId)
              .maybeSingle();
          debugPrint('[SEED] Confirmación (select) = $confirm');
        } catch (docError, st) {
          debugPrint('[SEED] ⛔ Error procesando ${doc.email}: $docError');
          debugPrint('[SEED] StackTrace: $st');
        }
      }

      // ── NO guardar SharedPreferences hasta que todo funcione ──
      // await prefs.setBool(_seedKey, true);
      debugPrint('[SEED] ⚠ SharedPreferences NO guardado (debug)');
      debugPrint('[SEED] ✅ Seed completado exitosamente');
    } catch (e, st) {
      debugPrint('[SEED] ⛔ Error global: $e');
      debugPrint('[SEED] StackTrace: $st');
    }

    debugPrint('[SEED] ====== FIN ======');
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
