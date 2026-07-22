abstract class IGeocodingService {
  Future<({double lat, double lng})?> locationFromAddress(String address);
}
