import 'dart:io';

abstract class IS3UploadService {
  Future<String> uploadImage(File file, {String? path});
}
