import 'package:dio/dio.dart';

import '../models/driver.dart';
import 'driver_repository.dart';

/// Fleet data from the Spring Boot API (`GET /api/drivers`).
class ApiDriverRepository implements DriverRepository {
  ApiDriverRepository(this._dio);

  final Dio _dio;
  List<Driver> _cache = [];

  @override
  List<Driver> get current => List.unmodifiable(_cache);

  @override
  Future<List<Driver>> getDrivers() async {
    final res = await _dio.get('/drivers');
    _cache = (res.data as List)
        .map((e) => Driver.fromJson(e as Map<String, dynamic>))
        .toList();
    return List.unmodifiable(_cache);
  }

  @override
  Future<Driver?> getDriver(String id) async {
    try {
      final res = await _dio.get('/drivers/$id');
      return Driver.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Driver> setStatus(String id, DriverStatus status) async {
    // Driver availability is managed server-side by the dispatch engine.
    throw UnimplementedError('Driver status is managed by the backend');
  }
}
