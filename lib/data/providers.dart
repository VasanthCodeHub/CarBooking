import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/driver_repository.dart';

/// Single place that wires up the data layer. When the Python API lands,
/// swap the mock implementations here for the Dio-backed ones — nothing
/// in the feature layer changes.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return MockDriverRepository();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return MockBookingRepository(ref.watch(driverRepositoryProvider));
});
