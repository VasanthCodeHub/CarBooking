import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/booking.dart';
import '../../../data/providers.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

/// How often we re-check the backend while a ride is in progress. Polling only
/// runs when there's a live booking and stops the moment everything settles.
const _pollInterval = Duration(seconds: 3);

/// Exposes the signed-in customer's reservations and keeps them fresh after
/// create/cancel actions. While a ride is live it silently polls the backend so
/// the UI reflects driver stage changes (assigned → on the way → arrived →
/// on trip → completed) in near real-time, without a manual pull-to-refresh.
class CustomerBookingsViewModel extends AsyncNotifier<List<Booking>> {
  Timer? _pollTimer;

  @override
  Future<List<Booking>> build() async {
    ref.onDispose(_stopPolling);
    final user = ref.watch(authViewModelProvider).user;
    if (user == null) {
      _stopPolling();
      return [];
    }
    final bookings = await ref.read(bookingRepositoryProvider).forCustomer(user.id);
    _syncPolling(bookings);
    return bookings;
  }

  Future<void> refresh() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookingRepositoryProvider).forCustomer(user.id),
    );
    final list = state.valueOrNull;
    if (list != null) _syncPolling(list);
  }

  Future<void> cancel(String bookingId) async {
    await ref.read(bookingRepositoryProvider).cancel(bookingId);
    await refresh();
  }

  /// Starts the poll timer if any booking is still live, otherwise stops it.
  void _syncPolling(List<Booking> bookings) {
    final hasLive = bookings.any((b) => b.status.isLive);
    if (hasLive) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => _poll());
    } else {
      _stopPolling();
    }
  }

  /// Silent refresh: refetch and swap the data in without flipping to a loading
  /// state, so watching screens just rebuild with the new statuses.
  Future<void> _poll() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      _stopPolling();
      return;
    }
    try {
      final bookings = await ref.read(bookingRepositoryProvider).forCustomer(user.id);
      state = AsyncData(bookings);
      _syncPolling(bookings);
    } catch (_) {
      // Keep the last good data and try again on the next tick.
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  List<Booking> get active =>
      (state.valueOrNull ?? []).where((b) => b.status.isLive).toList();

  List<Booking> get past => (state.valueOrNull ?? [])
      .where((b) => !b.status.isLive)
      .toList();
}

final customerBookingsProvider =
    AsyncNotifierProvider<CustomerBookingsViewModel, List<Booking>>(
        CustomerBookingsViewModel.new);
