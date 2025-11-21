import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/waste_summary.dart';

class TrackService {
  TrackService({
    this.baseUrl =
        'https://zigma.in/d2d/folders/waste_collected_summary_report/waste_collected_data_api.php',
    this.apiKey = 'ZIGMA-DELHI-WEIGHMENT-2025-SECURE',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  Future<Map<String, WasteSummary>> fetchMonthlySummaries(DateTime reference) async {
    final monthStart = DateTime(reference.year, reference.month, 1);
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'from_date': _dateKey(monthStart),
        'key': apiKey,
      },
    );
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch live data');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>?;
    final Map<String, WasteSummary> freshData = {};
    if (dataList != null) {
      for (final raw in dataList) {
        if (raw is Map<String, dynamic>) {
          final summary = WasteSummary.fromJson(raw);
          final String key = _dateKey(summary.date);
          freshData[key] = summary;
        }
      }
    }
    return freshData;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
