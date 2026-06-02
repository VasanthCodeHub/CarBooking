import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/mock_map.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/booking.dart';
import '../viewmodel/driver_viewmodel.dart';

class DriverRideDetailScreen extends ConsumerWidget {
  const DriverRideDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverViewModelProvider);
    final booking = async.valueOrNull?.rides
        .cast<Booking?>()
        .firstWhere((b) => b!.id == bookingId, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: Text('Ride #$bookingId')),
      body: booking == null
          ? const Center(child: CircularProgressIndicator())
          : _Body(booking: booking),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = RideAction.forStatus(booking.status);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              MockMap(
                height: 200,
                pickup: booking.pickup.position,
                dropoff: booking.dropoff.position,
                routeProgress:
                    booking.status == BookingStatus.onTrip ? 0.6 : null,
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                        initials: booking.customerName
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join(),
                        color: AppColors.primary,
                        size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('${booking.passengers} passenger(s)',
                              style: const TextStyle(
                                  color: AppColors.inkSoft, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    _circleBtn(Icons.call_rounded),
                    const SizedBox(width: 8),
                    _circleBtn(Icons.message_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _routeCard(),
              if (booking.notes != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sticky_note_2_outlined,
                          color: AppColors.amber, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(booking.notes!,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _fareCard(),
            ],
          ),
        ),
        if (action != null)
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => ref
                    .read(driverViewModelProvider.notifier)
                    .advance(booking.id, action.next),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.driver),
                child: Text(action.label),
              ),
            ),
          ),
      ],
    );
  }

  Widget _circleBtn(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.driver.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.driver, size: 18),
      );

  Widget _routeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _point(AppColors.success, 'Pickup', booking.pickup.label,
              booking.pickup.address),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          _point(AppColors.danger, 'Drop-off', booking.dropoff.label,
              booking.dropoff.address),
        ],
      ),
    );
  }

  Widget _point(Color color, String tag, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tag,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 12)),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(address,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fareCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.driverGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trip fare',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              SizedBox(height: 2),
              Text('You earn 80%',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5)),
            ],
          ),
          const Spacer(),
          Text(Fmt.money(booking.fare * 0.8),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
        ],
      ),
    );
  }
}
