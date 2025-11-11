import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/site_polygon.dart';

class SiteRepository {
  final Dio dioClient;
  SiteRepository({required this.dioClient});

  static const _endpoint =
      'https://api.vamosys.com/v2/viewSiteV2?userId=BLUEPLANET';

  Future<List<SitePolygon>> fetchSites() async {
    try {
      final resp = await dioClient.get(_endpoint);
      final data = resp.data as Map<String, dynamic>;
      final siteParents = (data['data']?['siteParent'] as List?) ?? const [];
      if (siteParents.isEmpty) return const [];
      final List<SitePolygon> polys = [];
      for (final parent in siteParents) {
        final parentMap = parent as Map<String, dynamic>?;
        if (parentMap == null) continue;
        final sites = (parentMap['site'] as List?) ?? const [];
        for (final s in sites) {
          final siteMap = s as Map<String, dynamic>?;
          if (siteMap == null) continue;
          final name = (siteMap['siteName'] ?? '').toString();
          final latlong =
              (siteMap['latlong'] as List?)?.cast<String>() ?? const [];
          if (latlong.isEmpty) continue;
          final points = <LatLng>[];
          for (final p in latlong) {
            final parts = p.split(',');
            if (parts.length != 2) continue;
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat == null || lng == null) continue;
            points.add(LatLng(lat, lng));
          }
          if (points.length >= 3) {
            polys.add(SitePolygon(name: name, points: points));
          }
        }
      }
      return polys;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to fetch site polygons: $e');
      }
      return const [];
    }
  }
}
