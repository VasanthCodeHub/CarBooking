import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/booking_card.dart';
import '../../../core/widgets/mock_map.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/driver.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/driver_viewmodel.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final driver = data.driver;
            return RefreshIndicator(
              onRefresh: () => ref.read(driverViewModelProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back', style: context.muted),
                          Text(user?.name.split(' ').first ?? 'Driver',
                              style: context.h2),
                        ],
                      ),
                      const Spacer(),
                      if (driver != null)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.amber),
                            Text(driver.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (driver != null)
                    _OnlineCard(
                      driver: driver,
                      onToggle: () =>
                          ref.read(driverViewModelProvider.notifier).toggleOnline(),
                    ),
                  const SizedBox(height: 18),
                  _StatsRow(data: data),
                  const SizedBox(height: 22),
                  if (data.activeRide != null) ...[
                    Text('Current ride', style: context.sectionTitle),
                    const SizedBox(height: 12),
                    _ActiveRideCard(
                      booking: data.activeRide!,
                      onAction: (next) => ref
                          .read(driverViewModelProvider.notifier)
                          .advance(data.activeRide!.id, next),
                      onTap: () =>
                          context.push('/driver/ride/${data.activeRide!.id}'),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Row(
                    children: [
                      Text('Incoming rides', style: context.sectionTitle),
                      const Spacer(),
                      Text('${data.assigned.length} assigned',
                          style: context.muted),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (data.assigned.isEmpty)
                    _EmptyAssigned(online: driver?.status != DriverStatus.offline)
                  else
                    for (final b in data.assigned)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookingCard(
                          booking: b,
                          subtitle:
                              '${b.customerName} • ${Fmt.whenLabel(b.scheduledAt)}',
                          onTap: () => context.push('/driver/ride/${b.id}'),
                          trailing: FilledButton(
                            onPressed: () => ref
                                .read(driverViewModelProvider.notifier)
                                .advance(b.id, BookingStatus.enRoute),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.driver,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Start'),
                          ),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnlineCard extends StatelessWidget {
  const _OnlineCard({required this.driver, required this.onToggle});
  final Driver driver;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final online = driver.status != DriverStatus.offline;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: online ? AppColors.driverGradient : null,
        color: online ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: online ? null : Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                online ? "You're online" : "You're offline",
                style: TextStyle(
                  color: online ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                driver.status == DriverStatus.onTrip
                    ? 'On a trip — finish to change status'
                    : online
                        ? 'Auto-dispatch can assign you rides'
                        : 'Go online to receive auto-assigned rides',
                style: TextStyle(
                  color: online
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.inkSoft,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Switch(
            value: online,
            onChanged:
                driver.status == DriverStatus.onTrip ? null : (_) => onToggle(),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});
  final DriverData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _stat(Icons.payments_rounded, Fmt.money(data.earningsToday),
              "Today's earnings"),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _stat(Icons.check_circle_rounded,
              '${data.completed.length}', 'Trips done'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _stat(Icons.timelapse_rounded,
              '${data.assigned.length + (data.activeRide != null ? 1 : 0)}', 'Active'),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.driver, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _ActiveRideCard extends StatelessWidget {
  const _ActiveRideCard({
    required this.booking,
    required this.onAction,
    required this.onTap,
  });
  final Booking booking;
  final void Function(BookingStatus next) onAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final action = RideAction.forStatus(booking.status);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.driver.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: MockMap(
              height: 140,
              borderRadius: 0,
              pickup: booking.pickup.position,
              dropoff: booking.dropoff.position,
              routeProgress: booking.status == BookingStatus.onTrip ? 0.6 : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(
                            booking.status == BookingStatus.onTrip
                                ? 'Heading to ${booking.dropoff.label}'
                                : 'Pickup at ${booking.pickup.label}',
                            style: const TextStyle(
                                color: AppColors.inkSoft, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                        label: booking.status.label,
                        color: booking.status.color),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniBtn(Icons.call_rounded, 'Call'),
                    const SizedBox(width: 10),
                    _miniBtn(Icons.navigation_rounded, 'Navigate'),
                    const Spacer(),
                    Text(Fmt.money(booking.fare),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 14),
                if (action != null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => onAction(action.next),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.driver),
                      child: Text(action.label),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.driver),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
      );
}

class _EmptyAssigned extends StatelessWidget {
  const _EmptyAssigned({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(online ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
              size: 40, color: AppColors.driver),
          const SizedBox(height: 12),
          Text(online ? 'Waiting for assignments' : 'You are offline',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            online
                ? 'New rides are dispatched to you automatically.'
                : 'Go online to start receiving rides.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
