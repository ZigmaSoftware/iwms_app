import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// This function creates and configures a Dio instance
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      // You can set a base URL here if all requests share one
      // baseUrl: 'http://zigma.in:80/iwms_app/iwms_app/',
      connectTimeout: const Duration(seconds: 10), // Increased timeout
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // You can add interceptors here for logging or auth tokens
  if (!kReleaseMode) {
    dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
  }

  return dio;
}

class ApiConfig {
  static const String driverLogin = 'http://zigma.in/iwms_app/iwms_app/login.php';
  static const String citizenRegister =
      'https://zigma.in/iwms_app/iwms_app/citizen_register.php';
  static const String citizenLogin =
      'https://zigma.in/iwms_app/iwms_app/citizen_login.php';
}

// Base URL (without query params)
const String kVehicleApiBaseUrl =
    "https://api.vamosys.com/mobile/getGrpDataForTrustedClients";

// API Parameters (ZIGMA specific credentials - THESE MUST BE PROTECTED!)
const String kProviderName = "BLUEPLANET";
const String kFCode = "VAM";
