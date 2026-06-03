import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../viewmodel/driver_viewmodel.dart';

class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(driverViewModelProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.driverGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total earned',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(Fmt.money(data?.earningsTotal ?? 0),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 34)),
                const SizedBox(height: 6),
                Text('From ${data?.completed.length ?? 0} completed trips',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _stat(Icons.today_rounded, Fmt.money(data?.earningsToday ?? 0),
                    'Today'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _stat(Icons.check_circle_rounded,
                    '${data?.completed.length ?? 0}', 'Trips total'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stat(Icons.account_balance_wallet_rounded,
                    Fmt.money(data?.earningsTotal ?? 0), 'All-time'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _stat(Icons.trending_up_rounded, '80%', 'Your share'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
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
          Icon(icon, color: AppColors.driver, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
        ],
      ),
    );
  }
}

