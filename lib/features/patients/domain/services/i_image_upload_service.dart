import 'dart:io';

abstract class IImageUploadService {
  Future<String> uploadImage(File file, {String? path});
}
