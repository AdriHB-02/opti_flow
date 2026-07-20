import 'dart:io';

abstract class ICameraService {
  Future<File?> takePhoto();
}
