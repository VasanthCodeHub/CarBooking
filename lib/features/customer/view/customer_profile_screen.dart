import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                AppAvatar(
                  initials: user?.initials ?? '?',
                  color: Colors.white,
                  imageUrl: user?.avatarUrl,
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Guest',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _tile(Icons.credit_card_rounded, 'Payment methods', 'Visa •••• 4242'),
          _tile(Icons.place_rounded, 'Saved places', 'Home, Office, +4'),
          _tile(Icons.history_rounded, 'Ride history', null),
          _tile(Icons.notifications_none_rounded, 'Notifications', null),
          _tile(Icons.help_outline_rounded, 'Help & support', null),
          const SizedBox(height: 12),
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

  Widget _tile(IconData icon, String title, String? subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.inkSoft),
        onTap: () {},
      ),
    );
  }
}
