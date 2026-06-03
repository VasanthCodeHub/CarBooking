import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL of the Spring Boot backend (port 8085, `/api` prefix).
///
/// Pick the host that matches where you run the app:
///   - Physical device  -> your PC's LAN IP (phone must be on the SAME Wi-Fi)
///   - Android emulator -> 10.0.2.2
///   - Web / desktop    -> localhost
// const String _lanHost = '192.168.13.62'; // <-- physical device (this PC's LAN IP)
const String _lanHost = '10.0.2.2';          // <-- Android emulator

String get apiBaseUrl {
  if (kIsWeb) return 'http://localhost:8085/api';
  return 'http://$_lanHost:8085/api';
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Log every request / response / error to the console in debug builds.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );
  }

  return dio;
});
