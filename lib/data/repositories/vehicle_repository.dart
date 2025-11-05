import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode/print

// Layered imports
import '../models/vehicle_model.dart';
import '../../core/api_config.dart'; 

// Using composed URL as fixed earlier
const String _liveLocationApi = 
    "$kVehicleApiBaseUrl?providerName=$kProviderName&fcode=$kFCode";

class VehicleRepository {
  final Dio dioClient;

  VehicleRepository({
    required this.dioClient,
  });

  // 2. Fetch data from the live API
  Future<List<VehicleModel>> fetchAllVehicleLocations() async {
    try {
      final Response response = await dioClient.get(_liveLocationApi);

      if (response.statusCode == 200 && response.data != null) {
        // 🟢 FIX: Mirroring test logic: Assume the direct response.data is the List, 
        // OR the response is an empty list if null/wrong type to prevent crashes.
        final List<dynamic> dataList = response.data is List ? response.data as List<dynamic> : [];

        // Map the list of raw JSON objects to Dart VehicleModel objects
        return dataList.map((json) => VehicleModel.fromJson(json)).toList();

      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: "API returned status code: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Network Error fetching vehicles: ${e.message}');
      }
      throw Exception("Network Error: Could not connect to API.");
    } catch (e) {
      if (kDebugMode) {
        print('Parsing/Format Error: $e');
      }
      throw Exception("Failed to process vehicle data. Check model keys and API format.");
    }
  }
}
