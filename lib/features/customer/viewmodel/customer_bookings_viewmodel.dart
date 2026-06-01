import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/booking.dart';
import '../../../data/providers.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

/// Exposes the signed-in customer's reservations and keeps them fresh after
/// create/cancel actions.
class CustomerBookingsViewModel extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final user = ref.watch(authViewModelProvider).user;
    if (user == null) return [];
    return ref.read(bookingRepositoryProvider).forCustomer(user.id);
  }

  Future<void> refresh() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookingRepositoryProvider).forCustomer(user.id),
    );
  }

  Future<void> cancel(String bookingId) async {
    await ref.read(bookingRepositoryProvider).cancel(bookingId);
    await refresh();
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
