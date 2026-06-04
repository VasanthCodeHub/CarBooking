import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL of the Spring Boot backend (port 8085, `/api` prefix).
///
/// We tunnel the local backend through ngrok so any device (physical phone on
/// mobile data, emulator, web) can reach it over HTTPS — no LAN/IP juggling.
/// When the ngrok tunnel restarts it gets a NEW url; paste it here.
const String _ngrokUrl = 'https://district-body-stumbling.ngrok-free.dev';

// ── Local fallbacks (uncomment ONE if you stop using ngrok) ───────────────
//   - Android emulator -> http://10.0.2.2:8085
//   - Physical device over USB -> http://localhost:8085 (+ `adb reverse tcp:8085 tcp:8085`)
//   - Web / desktop -> http://localhost:8085

String get apiBaseUrl => '$_ngrokUrl/api';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        // Skip ngrok's free-tier browser interstitial so we get raw JSON.
        'ngrok-skip-browser-warning': 'true',
      },
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
