import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/booking_card.dart';
import '../../../data/models/booking.dart';
import '../viewmodel/customer_bookings_viewmodel.dart';

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(customerBookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My trips'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Active'), Tab(text: 'History')],
          ),
        ),
        body: bookings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            final active = list.where((b) => b.status.isLive).toList();
            final past = list.where((b) => !b.status.isLive).toList();
            return TabBarView(
              children: [
                _TripList(
                  bookings: active,
                  emptyText: 'No active rides right now.',
                  onRefresh: () =>
                      ref.read(customerBookingsProvider.notifier).refresh(),
                ),
                _TripList(
                  bookings: past,
                  emptyText: 'Your completed rides will appear here.',
                  onRefresh: () =>
                      ref.read(customerBookingsProvider.notifier).refresh(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList({
    required this.bookings,
    required this.emptyText,
    required this.onRefresh,
  });
  final List<Booking> bookings;
  final String emptyText;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.receipt_long_rounded,
                size: 56, color: AppColors.line),
            const SizedBox(height: 12),
            Center(
              child: Text(emptyText,
                  style: const TextStyle(color: AppColors.inkSoft)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => BookingCard(
          booking: bookings[i],
          onTap: () => context.push('/customer/trip/${bookings[i].id}'),
        ),
      ),
    );
  }
}
