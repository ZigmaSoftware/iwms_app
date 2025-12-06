import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ORSService {
  // IMPORTANT: Replace with your real ORS key
  static const String apiKey = String.fromEnvironment(
    'ORS_API_KEY',
    defaultValue:
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjU3MzI5ZTM0NjM3YTQ2N2ZhZDYwMDM0ZmQ3ZDk0NTc3IiwiaCI6Im11cm11cjY0In0=',
  );

  // ---------------------------------------------------------------------------
  // ROUTE FETCH
  // ---------------------------------------------------------------------------
  static Future<List<LatLng>> fetchRoute(
      LatLng origin, LatLng destination) async {
    try {
      if (origin == null || destination == null) {
        print("ORS ERROR: origin/destination is null");
        return [];
      }

      final url = Uri.parse(
        "https://api.openrouteservice.org/v2/directions/driving-car"
        "?api_key=$apiKey"
        "&start=${origin.longitude},${origin.latitude}"
        "&end=${destination.longitude},${destination.latitude}",
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print("ORS ERROR: HTTP ${response.statusCode}");
        print(response.body);
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded == null ||
          decoded["features"] == null ||
          decoded["features"].isEmpty ||
          decoded["features"][0]["geometry"] == null) {
        print("ORS ERROR: geometry missing");
        return [];
      }

      final coords =
          decoded["features"][0]["geometry"]["coordinates"] as List<dynamic>;

      final List<LatLng> points = [];

      for (final c in coords) {
        if (c is List && c.length == 2) {
          final lat = (c[1] is num) ? c[1].toDouble() : null;
          final lon = (c[0] is num) ? c[0].toDouble() : null;

          if (lat != null && lon != null) {
            points.add(LatLng(lat, lon));
          }
        }
      }

      return points;
    } catch (e, st) {
      print("ORS EXCEPTION: $e");
      print(st);
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // BEARING CALCULATION
  // ---------------------------------------------------------------------------
  static double calculateBearing(LatLng from, LatLng to) {
    try {
      final lat1 = from.latitude * (pi / 180);
      final lat2 = to.latitude * (pi / 180);
      final dLon = (to.longitude - from.longitude) * (pi / 180);

      final y = sin(dLon) * cos(lat2);
      final x =
          cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

      double brng = atan2(y, x);
      brng = brng * 180 / pi;
      brng = (brng + 360) % 360;

      return brng;
    } catch (_) {
      return 0.0;
    }
  }
}
