import 'package:geolocator/geolocator.dart';

class LocationService {
  static double? _latitude;
  static double? _longitude;

  /// Request permission and fetch current position
  static Future<void> initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _latitude = pos.latitude;
    _longitude = pos.longitude;
  }

  /// Return latitude or 0.0 if not available
  static double get latitude => _latitude ?? 0.0;
  /// Return longitude or 0.0 if not available
  static double get longitude => _longitude ?? 0.0;

  /// Refresh coordinates manually (for updates)
  static Future<void> refresh() async => await initLocation();
}
