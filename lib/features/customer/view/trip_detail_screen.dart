import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/mock_map.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/driver.dart';
import '../../../data/providers.dart';
import '../viewmodel/customer_bookings_viewmodel.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(customerBookingsProvider);
    final booking = bookings.valueOrNull
        ?.cast<Booking?>()
        .firstWhere((b) => b!.id == bookingId, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: Text('Trip #$bookingId')),
      body: booking == null
          ? const Center(child: CircularProgressIndicator())
          : _Detail(booking: booking),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.booking});
  final Booking booking;

  double get _progress => switch (booking.status) {
        BookingStatus.assigned => 0.0,
        BookingStatus.enRoute => 0.35,
        BookingStatus.arrived => 0.5,
        BookingStatus.onTrip => 0.8,
        BookingStatus.completed => 1.0,
        _ => 0.0,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = booking.driverId == null
        ? null
        : ref
            .read(driverRepositoryProvider)
            .current
            .cast<Driver?>()
            .firstWhere((d) => d!.id == booking.driverId, orElse: () => null);

    final canCancel = booking.status.isLive &&
        booking.status != BookingStatus.onTrip &&
        booking.status != BookingStatus.completed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        MockMap(
          height: 200,
          pickup: booking.pickup.position,
          dropoff: booking.dropoff.position,
          routeProgress: booking.status == BookingStatus.onTrip ? _progress : null,
          drivers: driver != null && booking.status != BookingStatus.onTrip
              ? [MapDriver(position: driver.position, highlighted: true)]
              : const [],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            StatusChip(
                label: booking.status.label,
                color: booking.status.color,
                filled: true),
            const Spacer(),
            Text(Fmt.whenLabel(booking.scheduledAt), style: context.muted),
          ],
        ),
        const SizedBox(height: 18),
        if (driver != null) _DriverCard(driver: driver),
        if (driver != null) const SizedBox(height: 18),
        Text('Trip status', style: context.sectionTitle),
        const SizedBox(height: 12),
        _Timeline(status: booking.status),
        const SizedBox(height: 18),
        Text('Ride details', style: context.sectionTitle),
        const SizedBox(height: 12),
        _DetailsCard(booking: booking),
        const SizedBox(height: 20),
        if (canCancel)
          OutlinedButton.icon(
            onPressed: () => _confirmCancel(context, ref),
            icon: const Icon(Icons.close_rounded, color: AppColors.danger),
            label: const Text('Cancel reservation',
                style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: const Text('This will release the assigned driver.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(customerBookingsProvider.notifier).cancel(booking.id);
    }
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.driverGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AppAvatar(
            initials: driver.initials,
            color: Colors.white,
            imageUrl: driver.avatarUrl,
            size: 54,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text('${driver.vehicle.displayName} • ${driver.vehicle.plate}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 15),
                    Text(' ${driver.rating} • ${driver.completedTrips} trips',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _circleBtn(Icons.call_rounded),
              const SizedBox(height: 8),
              _circleBtn(Icons.message_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final BookingStatus status;

  static const _steps = [
    (BookingStatus.assigned, 'Driver assigned', Icons.person_pin_circle_rounded),
    (BookingStatus.enRoute, 'On the way to pickup', Icons.directions_car_rounded),
    (BookingStatus.arrived, 'Driver arrived', Icons.flag_rounded),
    (BookingStatus.onTrip, 'On trip', Icons.navigation_rounded),
    (BookingStatus.completed, 'Completed', Icons.check_circle_rounded),
  ];

  int get _currentIndex {
    if (status == BookingStatus.pending) return -1;
    final i = _steps.indexWhere((s) => s.$1 == status);
    return i;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _steps.length; i++)
            _step(
              _steps[i].$2,
              _steps[i].$3,
              done: i <= _currentIndex,
              active: i == _currentIndex,
              isLast: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _step(String label, IconData icon,
      {required bool done, required bool active, required bool isLast}) {
    final color = done ? AppColors.primary : AppColors.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 16, color: done ? Colors.white : AppColors.inkSoft),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: done ? AppColors.ink : AppColors.inkSoft,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _row('Pickup', booking.pickup.address, Icons.my_location_rounded,
              AppColors.success),
          const Divider(height: 20),
          _row('Drop-off', booking.dropoff.address, Icons.place_rounded,
              AppColors.danger),
          const Divider(height: 20),
          _row('Schedule', Fmt.dayTime(booking.scheduledAt),
              Icons.calendar_month_rounded, AppColors.primary),
          const Divider(height: 20),
          _row('Vehicle • passengers',
              '${booking.vehicleType.label} • ${booking.passengers}',
              booking.vehicleType.icon, AppColors.primary),
          if (booking.notes != null) ...[
            const Divider(height: 20),
            _row('Notes', booking.notes!, Icons.sticky_note_2_outlined,
                AppColors.inkSoft),
          ],
          const Divider(height: 20),
          Row(
            children: [
              const Text('Total fare',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text(Fmt.money(booking.fare),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
