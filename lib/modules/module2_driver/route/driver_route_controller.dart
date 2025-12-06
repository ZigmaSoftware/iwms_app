import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Holds routing state for the driver.
class DriverRouteState {
  const DriverRouteState({
    this.loading = false,
    this.error,
    this.driver,
    this.destination,
    this.route = const [],
  });

  final bool loading;
  final String? error;
  final LatLng? driver;
  final LatLng? destination;
  final List<LatLng> route;

  DriverRouteState copyWith({
    bool? loading,
    String? error,
    LatLng? driver,
    LatLng? destination,
    List<LatLng>? route,
  }) {
    return DriverRouteState(
      loading: loading ?? this.loading,
      error: error,
      driver: driver ?? this.driver,
      destination: destination ?? this.destination,
      route: route ?? this.route,
    );
  }
}

/// Controller to fetch driver GPS, next house, and ORS route.
class DriverRouteController extends ChangeNotifier {
  DriverRouteController({
    required this.orsApiKey,
    required this.djangoNextHouseUrl,
    this.refreshInterval = const Duration(seconds: 4),
  });

  final String orsApiKey;
  final String djangoNextHouseUrl;
  final Duration refreshInterval;

  DriverRouteState _state = const DriverRouteState(loading: true);
  DriverRouteState get state => _state;

  Timer? _timer;

  Future<void> start() async {
    await _refresh();
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => _refresh());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refresh() async {
    try {
      _state = _state.copyWith(loading: true, error: null);
      notifyListeners();

      final position = await _locate();
      final driverPoint = LatLng(position.latitude, position.longitude);
      final destination = await _fetchNextHouse();
      if (destination == null) {
        _state = _state.copyWith(
          loading: false,
          driver: driverPoint,
          destination: null,
          route: const [],
          error: 'No destination assigned',
        );
        notifyListeners();
        return;
      }

      final route = await _fetchOrsRoute(driverPoint, destination);
      _state = DriverRouteState(
        loading: false,
        driver: driverPoint,
        destination: destination,
        route: route,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        loading: false,
        error: 'Unable to load route',
      );
      notifyListeners();
    }
  }

  Future<Position> _locate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 6),
    );
  }

  Future<LatLng?> _fetchNextHouse() async {
    final uri = Uri.parse(djangoNextHouseUrl);
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body);
    final lat = double.tryParse(data['lat']?.toString() ?? '');
    final lng = double.tryParse(data['lng']?.toString() ?? '');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<List<LatLng>> _fetchOrsRoute(LatLng start, LatLng end) async {
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car');
    final body = jsonEncode({
      "coordinates": [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ]
    });
    final resp = await http.post(
      url,
      headers: {
        'Authorization': orsApiKey,
        'Content-Type': 'application/json',
      },
      body: body,
    ).timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) throw Exception('ORS failed');
    final decoded = jsonDecode(resp.body);
    final coords = decoded['features']?[0]?['geometry']?['coordinates'];
    if (coords is List) {
      return coords
          .whereType<List>()
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
    }
    return [];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
