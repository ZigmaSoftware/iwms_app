import 'package:geolocator/geolocator.dart';

class OperatorLocationService {
  OperatorLocationService._();

  static double? _latitude;
  static double? _longitude;

  static double get latitude => _latitude ?? 0.0;
  static double get longitude => _longitude ?? 0.0;

  static Future<void> refresh() async {
    await _ensureEnabled();
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _latitude = position.latitude;
    _longitude = position.longitude;
  }

  static Future<void> _ensureEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
  }
}
