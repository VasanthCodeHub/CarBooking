import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/booking.dart';
import '../viewmodel/admin_viewmodel.dart';
import 'widgets/match_sheet.dart';

/// The auto-dispatch board: pending reservations on top, each showing the
/// engine's live best match. Operators can let it run or dispatch on demand —
/// proving dispatch is automatic, not manual.
class AdminDispatchBoardScreen extends ConsumerWidget {
  const AdminDispatchBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-dispatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(adminViewModelProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _EngineBanner(
                pending: data.pending.length,
                available: data.available.length,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Pending dispatch', style: context.sectionTitle),
                  const Spacer(),
                  if (data.pending.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => _dispatchAll(context, ref),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: Text('Dispatch all (${data.pending.length})'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.admin,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.pending.isEmpty)
                _AllClear()
              else
                for (final b in data.pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PendingCard(
                      booking: b,
                      onOpen: () => _openMatch(context, ref, b),
                    ),
                  ),
              const SizedBox(height: 22),
              Text('Recently dispatched', style: context.sectionTitle),
              const SizedBox(height: 12),
              if (data.live.isEmpty)
                const Text('No active rides yet.',
                    style: TextStyle(color: AppColors.inkSoft))
              else
                for (final b in data.live.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DispatchedRow(
                      booking: b,
                      driverName: _driverName(data, b.driverId),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  String? _driverName(AdminData data, String? driverId) {
    if (driverId == null) return null;
    final matches = data.drivers.where((d) => d.id == driverId);
    return matches.isEmpty ? null : matches.first.name;
  }

  Future<void> _dispatchAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final matched = await ref.read(adminViewModelProvider.notifier).dispatchAll();
    messenger.showSnackBar(SnackBar(
      content: Text('Auto-dispatched $matched ride(s) to nearest drivers'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _openMatch(BuildContext context, WidgetRef ref, Booking booking) {
    final result = ref.read(adminViewModelProvider.notifier).preview(booking);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MatchSheet(
        booking: booking,
        result: result,
        onDispatch: () async {
          await ref.read(adminViewModelProvider.notifier).dispatch(booking.id);
        },
      ),
    );
  }
}

class _EngineBanner extends StatelessWidget {
  const _EngineBanner({required this.pending, required this.available});
  final int pending;
  final int available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.adminGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Dispatch engine',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Running',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Matches each reservation to the nearest available driver by '
            'proximity, rating and vehicle fit — automatically.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pill('$pending', 'pending'),
              const SizedBox(width: 10),
              _pill('$available', 'available drivers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
          ],
        ),
      );
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.booking, required this.onOpen});
  final Booking booking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.read(adminViewModelProvider.notifier).preview(booking);
    final winner = result.winner;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${booking.id} • ${booking.customerName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      Text(
                          '${booking.pickup.label} → ${booking.dropoff.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 12.5)),
                    ],
                  ),
                ),
                StatusChip(
                    label: Fmt.whenLabel(booking.scheduledAt),
                    color: booking.isScheduled ? AppColors.info : AppColors.amber,
                    icon: booking.isScheduled
                        ? Icons.calendar_month_rounded
                        : Icons.bolt_rounded,
                    dense: true),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: winner != null
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                      winner != null
                          ? Icons.auto_awesome_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                      color: winner != null
                          ? AppColors.success
                          : AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      winner != null
                          ? 'Best match: ${winner.driver.name} • '
                              '${winner.etaMinutes.round()} min • '
                              'score ${winner.score.round()}/100'
                          : 'No available driver right now',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.inkSoft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatchedRow extends StatelessWidget {
  const _DispatchedRow({required this.booking, required this.driverName});
  final Booking booking;
  final String? driverName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: booking.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_rounded,
                size: 16, color: booking.status.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${booking.id} → ${driverName ?? 'Driver'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('${booking.customerName} • ${booking.vehicleType.label}',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          StatusChip(
              label: booking.status.label,
              color: booking.status.color,
              dense: true),
        ],
      ),
    );
  }
}

class _AllClear extends StatelessWidget {
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
          const Icon(Icons.check_circle_rounded,
              size: 44, color: AppColors.success),
          const SizedBox(height: 12),
          const Text('All rides dispatched',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'New reservations are auto-assigned the moment they come in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
