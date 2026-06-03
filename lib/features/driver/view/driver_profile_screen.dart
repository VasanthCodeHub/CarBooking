import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/driver_viewmodel.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final driver = ref.watch(driverViewModelProvider).valueOrNull?.driver;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.driverGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AppAvatar(
                      initials: driver?.initials ?? user?.initials ?? '?',
                      color: Colors.white,
                      imageUrl: driver?.avatarUrl,
                      size: 60,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver?.name ?? user?.name ?? 'Driver',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                          Text(driver?.zone ?? '',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    if (driver != null)
                      Column(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white),
                          Text(driver.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (driver != null) ...[
            _vehicleCard(driver.vehicle.displayName, driver.vehicle.plate,
                driver.vehicle.type.label, driver.vehicle.color),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _stat('${driver.completedTrips}', 'Total trips')),
                const SizedBox(width: 12),
                Expanded(child: _stat(driver.vehicle.type.label, 'Class')),
              ],
            ),
            const SizedBox(height: 20),
          ],
          OutlinedButton.icon(
            onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text('Log out',
                style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(String name, String plate, String type, String color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.driver.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_filled_rounded,
                color: AppColors.driver, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text('$color • $type',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(plate,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label,
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
          ],
        ),
      );

}
