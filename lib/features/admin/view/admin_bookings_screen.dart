import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/booking_card.dart';
import '../../../data/models/booking.dart';
import '../viewmodel/admin_viewmodel.dart';

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Pending', 'Active', 'Completed', 'Cancelled'];

  bool _matches(Booking b) => switch (_filter) {
        'Pending' => b.status == BookingStatus.pending,
        'Active' => b.status.isActive,
        'Completed' => b.status == BookingStatus.completed,
        'Cancelled' => b.status == BookingStatus.cancelled,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final list = data.bookings.where(_matches).toList();
          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final f in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.admin,
                          labelStyle: TextStyle(
                            color: _filter == f ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.line),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('No bookings in this view.',
                            style: TextStyle(color: AppColors.inkSoft)),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(adminViewModelProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => BookingCard(
                            booking: list[i],
                            subtitle: list[i].customerName,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
