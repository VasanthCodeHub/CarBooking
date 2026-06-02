import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/driver.dart';
import '../../../data/providers.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

/// Snapshot of everything the driver screens need.
@immutable
class DriverData {
  final Driver? driver;
  final List<Booking> rides;

  const DriverData({this.driver, this.rides = const []});

  /// The ride currently in motion (heading to pickup, arrived or on trip).
  Booking? get activeRide => rides
      .cast<Booking?>()
      .firstWhere(
        (b) =>
            b!.status == BookingStatus.enRoute ||
            b.status == BookingStatus.arrived ||
            b.status == BookingStatus.onTrip,
        orElse: () => null,
      );

  List<Booking> get assigned =>
      rides.where((b) => b.status == BookingStatus.assigned).toList();

  List<Booking> get upcoming =>
      rides.where((b) => b.status.isActive).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Booking> get completed =>
      rides.where((b) => b.status == BookingStatus.completed).toList();

  double get earningsToday {
    final now = DateTime.now();
    return completed
        .where((b) => b.scheduledAt.day == now.day && b.scheduledAt.month == now.month)
        .fold(0.0, (sum, b) => sum + b.fare);
  }

  double get earningsTotal => completed.fold(0.0, (sum, b) => sum + b.fare);
}

/// Maps a booking status to the action the driver takes next.
class RideAction {
  final String label;
  final BookingStatus next;
  const RideAction(this.label, this.next);

  static RideAction? forStatus(BookingStatus status) => switch (status) {
        BookingStatus.assigned => const RideAction('Start pickup', BookingStatus.enRoute),
        BookingStatus.enRoute => const RideAction('I have arrived', BookingStatus.arrived),
        BookingStatus.arrived => const RideAction('Start trip', BookingStatus.onTrip),
        BookingStatus.onTrip => const RideAction('Complete trip', BookingStatus.completed),
        _ => null,
      };
}

class DriverViewModel extends AsyncNotifier<DriverData> {
  String? get _driverId => ref.read(authViewModelProvider).user?.driverId;

  @override
  Future<DriverData> build() async {
    ref.watch(authViewModelProvider);
    return _load();
  }

  Future<DriverData> _load() async {
    final id = _driverId;
    if (id == null) return const DriverData();
    final driver = await ref.read(driverRepositoryProvider).getDriver(id);
    final rides = await ref.read(bookingRepositoryProvider).forDriver(id);
    return DriverData(driver: driver, rides: rides);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> toggleOnline() async {
    final driver = state.valueOrNull?.driver;
    if (driver == null || driver.status == DriverStatus.onTrip) return;
    final next = driver.status == DriverStatus.offline
        ? DriverStatus.available
        : DriverStatus.offline;
    await ref.read(driverRepositoryProvider).setStatus(driver.id, next);
    await refresh();
  }

  Future<void> advance(String bookingId, BookingStatus next) async {
    await ref.read(bookingRepositoryProvider).advanceStatus(bookingId, next);
    await refresh();
  }
}

final driverViewModelProvider =
    AsyncNotifierProvider<DriverViewModel, DriverData>(DriverViewModel.new);
