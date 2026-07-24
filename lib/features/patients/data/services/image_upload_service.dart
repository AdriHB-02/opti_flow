import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/i_image_upload_service.dart';

class ImageUploadService implements IImageUploadService {
  static const String _bucket = 'diagnosticos';

  final SupabaseClient _supabaseClient;

  ImageUploadService({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<String> uploadImage(File file, {String? path}) async {
    final fileName = path ?? '${const Uuid().v4()}.jpg';

    await _supabaseClient.storage.from(_bucket).upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final url = _supabaseClient.storage.from(_bucket).getPublicUrl(fileName);

    return url;
  }
}
