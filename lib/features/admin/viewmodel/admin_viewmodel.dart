import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/dispatch.dart';
import '../../../data/models/driver.dart';
import '../../../data/providers.dart';

/// Everything the admin screens render: all bookings + the whole fleet.
@immutable
class AdminData {
  final List<Booking> bookings;
  final List<Driver> drivers;

  const AdminData({this.bookings = const [], this.drivers = const []});

  List<Booking> get pending =>
      bookings.where((b) => b.status == BookingStatus.pending).toList();

  List<Booking> get live =>
      bookings.where((b) => b.status.isActive).toList();

  List<Booking> get scheduled => bookings
      .where((b) => b.status == BookingStatus.assigned && b.isScheduled)
      .toList();

  List<Driver> get online =>
      drivers.where((d) => d.status != DriverStatus.offline).toList();

  List<Driver> get available =>
      drivers.where((d) => d.status == DriverStatus.available).toList();

  int get completedToday {
    final now = DateTime.now();
    return bookings
        .where((b) =>
            b.status == BookingStatus.completed &&
            b.scheduledAt.day == now.day &&
            b.scheduledAt.month == now.month)
        .length;
  }

  double get revenueToday {
    final now = DateTime.now();
    return bookings
        .where((b) =>
            b.status == BookingStatus.completed &&
            b.scheduledAt.day == now.day &&
            b.scheduledAt.month == now.month)
        .fold(0.0, (s, b) => s + b.fare);
  }

  double get fleetUtilization {
    if (drivers.isEmpty) return 0;
    final busy = drivers.where((d) => d.status == DriverStatus.onTrip).length;
    return busy / drivers.length;
  }
}

class AdminViewModel extends AsyncNotifier<AdminData> {
  @override
  Future<AdminData> build() => _load();

  Future<AdminData> _load() async {
    final bookings = await ref.read(bookingRepositoryProvider).getAll();
    final drivers = await ref.read(driverRepositoryProvider).getDrivers();
    return AdminData(bookings: bookings, drivers: drivers);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Live preview of the ranked matches for a pending booking.
  DispatchResult preview(Booking booking) =>
      ref.read(bookingRepositoryProvider).previewDispatch(booking);

  /// Run auto-dispatch for one pending booking and refresh.
  Future<DispatchResult> dispatch(String bookingId) async {
    final result = await ref.read(bookingRepositoryProvider).redispatch(bookingId);
    await refresh();
    return result;
  }

  /// Dispatch every pending booking at once (the "auto" in auto-dispatch).
  Future<int> dispatchAll() async {
    final pendingIds =
        state.valueOrNull?.pending.map((b) => b.id).toList() ?? [];
    var matched = 0;
    for (final id in pendingIds) {
      final r = await ref.read(bookingRepositoryProvider).redispatch(id);
      if (r.matched) matched++;
    }
    await refresh();
    return matched;
  }
}

final adminViewModelProvider =
    AsyncNotifierProvider<AdminViewModel, AdminData>(AdminViewModel.new);
