import 'package:flutter/material.dart';

import '../../data/models/booking.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

/// Compact summary of a booking: route, schedule, vehicle, fare and status.
/// Used in customer trips, driver lists and the admin board.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.trailing,
    this.subtitle,
  });

  final Booking booking;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: booking.vehicleType.fareMultiplier > 1.5
                          ? AppColors.admin.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(booking.vehicleType.icon,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${booking.vehicleType.label} • #${booking.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle ?? Fmt.whenLabel(booking.scheduledAt),
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(label: booking.status.label, color: booking.status.color),
                ],
              ),
              const SizedBox(height: 14),
              _RouteRow(booking: booking),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MetaPill(
                    icon: Icons.route_rounded,
                    text: Fmt.km(booking.distanceKm),
                  ),
                  const SizedBox(width: 8),
                  _MetaPill(
                    icon: Icons.payments_rounded,
                    text: Fmt.money(booking.fare),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _point(AppColors.success, booking.pickup.label, booking.pickup.address),
        Padding(
          padding: const EdgeInsets.only(left: 5.5),
          child: Column(
            children: List.generate(
              3,
              (_) => Container(
                height: 3,
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 1.5),
                color: AppColors.line,
              ),
            ),
          ),
        ),
        _point(AppColors.danger, booking.dropoff.label, booking.dropoff.address),
      ],
    );
  }

  Widget _point(Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5)),
              Text(address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkSoft),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}
