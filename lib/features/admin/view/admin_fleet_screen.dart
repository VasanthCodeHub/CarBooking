import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/mock_map.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/driver.dart';
import '../viewmodel/admin_viewmodel.dart';

class AdminFleetScreen extends ConsumerStatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  ConsumerState<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends ConsumerState<AdminFleetScreen> {
  DriverStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fleet')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final drivers = _filter == null
              ? data.drivers
              : data.drivers.where((d) => d.status == _filter).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              MockMap(
                height: 180,
                showRoute: false,
                drivers: data.drivers
                    .where((d) => d.status != DriverStatus.offline)
                    .map((d) => MapDriver(
                          position: d.position,
                          color: d.status.color,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', null, data.drivers.length),
                    _chip('Available', DriverStatus.available,
                        data.available.length),
                    _chip(
                        'On trip',
                        DriverStatus.onTrip,
                        data.drivers
                            .where((d) => d.status == DriverStatus.onTrip)
                            .length),
                    _chip(
                        'Offline',
                        DriverStatus.offline,
                        data.drivers
                            .where((d) => d.status == DriverStatus.offline)
                            .length),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...drivers.map((d) => _DriverCard(driver: d)),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, DriverStatus? status, int count) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.admin : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.admin : AppColors.line),
          ),
          child: Text(
            '$label · $count',
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(
                  initials: driver.initials,
                  color: driver.status.color,
                  imageUrl: driver.avatarUrl,
                  size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('${driver.vehicle.displayName} • ${driver.vehicle.plate}',
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusChip(
                  label: driver.status.label,
                  color: driver.status.color,
                  dense: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.star_rounded, driver.rating.toStringAsFixed(1),
                  AppColors.amber),
              const SizedBox(width: 16),
              _meta(Icons.check_circle_rounded, '${driver.completedTrips}',
                  AppColors.driver),
              const SizedBox(width: 16),
              _meta(Icons.place_rounded, driver.zone, AppColors.primary),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(driver.vehicle.type.label,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color) => Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      );
}
