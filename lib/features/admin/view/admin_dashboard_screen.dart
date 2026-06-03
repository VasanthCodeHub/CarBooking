import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/mock_map.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/driver.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/admin_viewmodel.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.read(adminViewModelProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Operations', style: context.muted),
                        Text(user?.name.split(' ').first ?? 'Admin',
                            style: context.h2),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 16, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Auto-dispatch ON',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _kpi(Icons.directions_car_rounded, '${data.live.length}',
                        'Active rides', AppColors.primary),
                    _kpi(Icons.pending_actions_rounded, '${data.pending.length}',
                        'Pending dispatch', AppColors.amber),
                    _kpi(Icons.groups_rounded,
                        '${data.online.length}/${data.drivers.length}',
                        'Drivers online', AppColors.driver),
                    _kpi(Icons.payments_rounded, Fmt.money(data.revenueToday),
                        'Revenue today', AppColors.admin),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Live fleet map', style: context.sectionTitle),
                    const Spacer(),
                    Text('${data.available.length} available',
                        style: context.muted),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    MockMap(
                      height: 220,
                      showRoute: false,
                      drivers: data.drivers
                          .where((d) => d.status != DriverStatus.offline)
                          .map((d) => MapDriver(
                                position: d.position,
                                color: d.status == DriverStatus.available
                                    ? AppColors.driver
                                    : AppColors.info,
                              ))
                          .toList(),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          _legend(AppColors.driver, 'Available'),
                          const SizedBox(width: 8),
                          _legend(AppColors.info, 'On trip'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Fleet status', style: context.sectionTitle),
                const SizedBox(height: 12),
                _UtilizationBar(value: data.fleetUtilization),
                const SizedBox(height: 12),
                ...data.drivers.take(4).map((d) => _DriverRow(driver: d)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpi(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 22)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
                height: 8,
                width: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _UtilizationBar extends StatelessWidget {
  const _UtilizationBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Fleet utilization',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(value * 100).round()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.admin)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.admin),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: driver.status.color.withValues(alpha: 0.15),
            child: Text(driver.initials,
                style: TextStyle(
                    color: driver.status.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${driver.vehicle.displayName} • ${driver.zone}',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          StatusChip(
              label: driver.status.label, color: driver.status.color, dense: true),
        ],
      ),
    );
  }
}
