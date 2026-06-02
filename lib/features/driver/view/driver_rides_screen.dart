import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/booking_card.dart';
import '../../../data/models/booking.dart';
import '../viewmodel/driver_viewmodel.dart';

class DriverRidesScreen extends ConsumerWidget {
  const DriverRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverViewModelProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My rides'),
          bottom: const TabBar(
            labelColor: AppColors.driver,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.driver,
            tabs: [Tab(text: 'Upcoming'), Tab(text: 'Completed')],
          ),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) => TabBarView(
            children: [
              _list(context, ref, data.upcoming, 'No upcoming rides.'),
              _list(context, ref, data.completed, 'No completed rides yet.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(
      BuildContext context, WidgetRef ref, List<Booking> rides, String empty) {
    if (rides.isEmpty) {
      return Center(
        child: Text(empty, style: const TextStyle(color: AppColors.inkSoft)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(driverViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: rides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => BookingCard(
          booking: rides[i],
          subtitle:
              '${rides[i].customerName} • ${Fmt.whenLabel(rides[i].scheduledAt)}',
          onTap: () => context.push('/driver/ride/${rides[i].id}'),
        ),
      ),
    );
  }
}
