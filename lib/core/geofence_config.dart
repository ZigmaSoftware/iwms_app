import 'package:latlong2/latlong.dart';

/// Centralised configuration for static geofences used inside the app.
class GammaGeofenceConfig {
  const GammaGeofenceConfig._();

  static const String name = 'Gamma 1';

  /// Approximate centre point (used for map camera defaults).
  static final LatLng center = _polygon.fold<LatLng>(
    const LatLng(0, 0),
    (previousValue, point) => LatLng(
      previousValue.latitude + point.latitude / _polygon.length,
      previousValue.longitude + point.longitude / _polygon.length,
    ),
  );

  /// Lowercase hint taken from the provider address field for resilience.
  static const String addressHint =
      'blue planet integrated waste management facility';

  /// Polygon describing the Gamma 1 perimeter (clockwise order).
  static List<LatLng> get polygon => List.unmodifiable(_polygon);

  static const List<LatLng> _polygon = [
    LatLng(28.477070, 77.481530),
    LatLng(28.477180, 77.480510),
    LatLng(28.476720, 77.479880),
    LatLng(28.475890, 77.479790),
    LatLng(28.475250, 77.480660),
    LatLng(28.475630, 77.481760),
  ];

  static final Distance _distance = Distance();

  /// Checks whether [point] lies inside the Gamma 1 polygon using a
  /// ray-casting algorithm.
  static bool contains(LatLng point) {
    final double x = point.longitude;
    final double y = point.latitude;
    bool inside = false;

    for (int i = 0, j = _polygon.length - 1; i < _polygon.length; j = i++) {
      final double xi = _polygon[i].longitude;
      final double yi = _polygon[i].latitude;
      final double xj = _polygon[j].longitude;
      final double yj = _polygon[j].latitude;

      final bool intersectY = ((yi > y) != (yj > y));
      if (!intersectY) continue;

      final double slope =
          (yj - yi).abs() < 1e-9 ? double.infinity : (xj - xi) / (yj - yi);
      final double xIntersection =
          slope.isInfinite ? xi : slope * (y - yi) + xi;

      if (x < xIntersection) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Returns true when [point] is within [toleranceMeters] of the polygon
  /// centre—used as a graceful fallback when API metadata only flags the
  /// facility without precise vertices.
  static bool isNear(LatLng point, {double toleranceMeters = 120}) {
    return _distance(point, center) <= toleranceMeters;
  }
}
