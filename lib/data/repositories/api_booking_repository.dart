import 'package:dio/dio.dart';

import '../models/booking.dart';
import '../models/dispatch.dart';
import 'booking_repository.dart';

/// Bookings backed by the Spring Boot API. Implements the customer-facing
/// slice; driver/admin-only operations throw until those endpoints exist.
class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._dio);

  final Dio _dio;

  @override
  List<Booking> get current => const [];

  @override
  Future<List<Booking>> forCustomer(String customerId) async {
    final res = await _dio.get(
      '/customer/bookings',
      queryParameters: {'customerId': customerId},
    );
    return (res.data as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Booking?> getById(String id) async {
    try {
      final res = await _dio.get('/customer/bookings/$id');
      return Booking.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<DispatchResult> createAndDispatch(Booking draft) async {
    final body = {
      'customer_id': draft.customerId,
      'customer_name': draft.customerName,
      'pickup': draft.pickup.toJson(),
      'dropoff': draft.dropoff.toJson(),
      'scheduled_at': draft.scheduledAt.toUtc().toIso8601String(),
      'vehicle_type': draft.vehicleType.name,
      'passengers': draft.passengers,
      'notes': draft.notes,
    };
    final res = await _dio.post('/customer/bookings', data: body);
    final dispatch =
        (res.data as Map<String, dynamic>)['dispatch'] as Map<String, dynamic>;
    return DispatchResult.fromJson(dispatch);
  }

  @override
  Future<Booking> cancel(String bookingId) async {
    final res = await _dio.post('/customer/bookings/$bookingId/cancel');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<Booking>> forDriver(String driverId) async {
    final res = await _dio.get(
      '/driver/bookings',
      queryParameters: {'driverId': driverId},
    );
    return (res.data as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Booking> advanceStatus(String bookingId, BookingStatus status) async {
    final res = await _dio.patch(
      '/driver/bookings/$bookingId/status',
      data: {'status': status.name},
    );
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Admin-only operations (endpoints come later) ──────────────────────────
  @override
  Future<List<Booking>> getAll() => throw UnimplementedError();

  @override
  Future<DispatchResult> redispatch(String bookingId) => throw UnimplementedError();

  @override
  DispatchResult previewDispatch(Booking booking) => throw UnimplementedError();
}
