import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/booking_card.dart';
import '../../../core/widgets/mock_map.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/customer_bookings_viewmodel.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final bookings = ref.watch(customerBookingsProvider);
    final active = bookings.valueOrNull?.where((b) => b.status.isLive).toList() ?? [];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(customerBookingsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good to see you 👋', style: context.muted),
                      const SizedBox(height: 2),
                      Text(user?.name.split(' ').first ?? 'there',
                          style: context.h2),
                    ],
                  ),
                  const Spacer(),
                  AppAvatar(
                    initials: user?.initials ?? '?',
                    imageUrl: user?.avatarUrl,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SearchCard(onTap: () => context.push('/customer/book'))
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              if (active.isNotEmpty) ...[
                Row(
                  children: [
                    Text('Active rides', style: context.sectionTitle),
                    const Spacer(),
                    Text('${active.length}', style: context.muted),
                  ],
                ),
                const SizedBox(height: 12),
                for (final b in active.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookingCard(
                      booking: b,
                      onTap: () => context.push('/customer/trip/${b.id}'),
                    ),
                  ),
              ] else
                _EmptyActive(onBook: () => context.push('/customer/book')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reserve a ride',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('Where to?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-dispatch finds your nearest driver instantly',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActive extends StatelessWidget {
  const _EmptyActive({required this.onBook});
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const MockMap(height: 140, showRoute: false, drivers: [
            MapDriver(position: LatLng(37.789, -122.432)),
            MapDriver(position: LatLng(37.768, -122.412)),
            MapDriver(position: LatLng(37.794, -122.421)),
          ]),
          const SizedBox(height: 16),
          const Text('No active rides',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Reserve a ride and we’ll auto-assign a driver.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBook,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book a ride'),
            ),
          ),
        ],
      ),
    );
  }
}
