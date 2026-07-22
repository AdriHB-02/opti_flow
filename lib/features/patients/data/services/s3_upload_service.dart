import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/i_s3_upload_service.dart';

class S3UploadService implements IS3UploadService {
  final SupabaseClient _supabaseClient;

  S3UploadService({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<String> uploadImage(File file, {String? path}) async {
    final fileName = path ?? '${const Uuid().v4()}.jpg';

    final response = await _supabaseClient.functions
        .invoke(
          'generate-s3-presign',
          body: {'fileName': fileName, 'contentType': 'image/jpeg'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.status != 200) {
      throw Exception(
        'Error al obtener URL de subida: ${response.status}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final presignedUrl = data['presignedUrl'] as String;
    final publicUrl = data['publicUrl'] as String;

    if (!presignedUrl.startsWith('https://')) {
      throw Exception('URL de subida no segura: se requiere HTTPS');
    }

    final fileBytes = await file.readAsBytes();

    final uploadResponse = await http
        .put(
          Uri.parse(presignedUrl),
          headers: {'Content-Type': 'image/jpeg'},
          body: fileBytes,
        )
        .timeout(const Duration(seconds: 60));

    if (uploadResponse.statusCode != 200) {
      throw Exception(
        'Error al subir imagen: ${uploadResponse.statusCode}',
      );
    }

    return publicUrl;
  }
}
