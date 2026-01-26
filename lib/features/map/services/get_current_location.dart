import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GetCurrentLocation {
  /// Returns current device location as LatLng
  static Future<LatLng> get() async {
    // 1️⃣ Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // 2️⃣ Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied',
      );
    }

    // 3️⃣ Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }
}
