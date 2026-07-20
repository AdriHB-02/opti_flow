abstract class IGpsService {
  Future<({double lat, double lng})> getCurrentLocation();

  Future<bool> checkAndRequestPermission();
}
