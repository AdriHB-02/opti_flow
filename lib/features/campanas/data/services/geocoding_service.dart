import 'package:geocoding/geocoding.dart';

import '../../domain/services/i_geocoding_service.dart';

class GeocodingService implements IGeocodingService {
  @override
  Future<({double lat, double lng})?> locationFromAddress(String address) async {
    try {
      final locations = await Geocoding.instance.locationFromAddress(address);
      if (locations.isEmpty) return null;
      return (lat: locations.first.latitude, lng: locations.first.longitude);
    } catch (_) {
      return null;
    }
  }
}
