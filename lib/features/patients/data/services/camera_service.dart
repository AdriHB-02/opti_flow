import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../domain/services/i_camera_service.dart';

class CameraService implements ICameraService {
  final ImagePicker _picker;

  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<File?> takePhoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );

    if (xFile == null) return null;
    return File(xFile.path);
  }
}
