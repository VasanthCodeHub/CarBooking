import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/driver.dart';
import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/driver_repository.dart';

/// Single place that wires up the data layer. When the Python API lands,
/// swap the mock implementations here for the Dio-backed ones — nothing
/// in the feature layer changes.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return StaticAuthRepository();
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return MockDriverRepository();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return MockBookingRepository(ref.watch(driverRepositoryProvider));
});

/// Current fleet, fetched once for map previews. Refresh by invalidating.
final fleetProvider = FutureProvider<List<Driver>>((ref) {
  return ref.watch(driverRepositoryProvider).getDrivers();
});
