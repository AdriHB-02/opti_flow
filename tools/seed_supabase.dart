// seed_supabase.dart
import 'dart:convert';
import 'dart:io';
import 'package:opti_flow/core/constants/app_constants.dart';



void main(List<String> args) async {
  final serviceRoleKey = args.isNotEmpty ? args[0] : null;

  final now = DateTime.now().toUtc().toIso8601String();
  final doctor = {
    'id': 'doc-${DateTime.now().millisecondsSinceEpoch}',
    'nombre': 'Dr. Seed',
    'email': 'seed@optiflow.com',
    'password_hash': 'seed_placeholder',
    'rol': 'USER',
    'activo': 1,
    'created_at': now,
    'updated_at': now,
  };

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('${AppConstants.supabaseUrl}/doctores'),
    );

    final bearerKey = serviceRoleKey ?? AppConstants.supabaseAnonKey;
    request.headers.set('apikey', AppConstants.supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $bearerKey');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'return=representation');
    request.add(utf8.encode(jsonEncode(doctor)));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 201) {
      print('\n=== DOCTOR INSERTED ===');
      print(responseBody);
      print('========================\n');
    } else {
      print('\nERROR (${response.statusCode}):');
      print(responseBody);

      if (response.statusCode == 401 || response.statusCode == 403) {
        print('\nRLS / permissions error. Provide your service_role key as argument:');
        print('  dart run tools/seed_supabase.dart "service-role-key-here"');
        print('Find it in Supabase Dashboard → Settings → API → service_role key');
      }
    }
  } finally {
    client.close();
  }
}
