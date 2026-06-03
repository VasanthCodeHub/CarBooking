import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/mock_map.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/dispatch.dart';

/// Shows the dispatch engine's ranked candidates for one pending booking,
/// the winning match's rationale, and a one-tap auto-dispatch action.
class MatchSheet extends StatefulWidget {
  const MatchSheet({
    super.key,
    required this.booking,
    required this.result,
    required this.onDispatch,
  });

  final Booking booking;
  final DispatchResult result;
  final Future<void> Function() onDispatch;

  @override
  State<MatchSheet> createState() => _MatchSheetState();
}

class _MatchSheetState extends State<MatchSheet> {
  bool _dispatching = false;

  Future<void> _dispatch() async {
    setState(() => _dispatching = true);
    await widget.onDispatch();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ranked = widget.result.ranked;
    final winner = widget.result.winner;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Text('Match #${widget.booking.id}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 20)),
                Text(
                  '${widget.booking.pickup.label} → ${widget.booking.dropoff.label}'
                  ' • ${widget.booking.vehicleType.label}',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 14),
                MockMap(
                  height: 170,
                  pickup: widget.booking.pickup.position,
                  dropoff: widget.booking.dropoff.position,
                  drivers: ranked
                      .map((c) => MapDriver(
                            position: c.driver.position,
                            highlighted: c.driver.id == winner?.driver.id,
                            color: c.driver.id == winner?.driver.id
                                ? AppColors.admin
                                : AppColors.driver,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 18),
                if (winner == null)
                  _noDriver()
                else ...[
                  const Text('Engine ranking',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  for (int i = 0; i < ranked.length; i++)
                    _CandidateTile(
                      candidate: ranked[i],
                      rank: i + 1,
                      isWinner: ranked[i].driver.id == winner.driver.id,
                    ),
                ],
              ],
            ),
          ),
          if (winner != null)
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _dispatching ? null : _dispatch,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.admin),
                  icon: _dispatching
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded),
                  label: Text(_dispatching
                      ? 'Dispatching…'
                      : 'Auto-dispatch to ${winner.driver.name.split(' ').first}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _noDriver() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 36),
            SizedBox(height: 10),
            Text('No available driver',
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text(
              'All drivers are offline or on a trip. The engine will assign one '
              'automatically as soon as a driver frees up.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
            ),
          ],
        ),
      );
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.rank,
    required this.isWinner,
  });
  final DispatchCandidate candidate;
  final int rank;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final d = candidate.driver;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.admin.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? AppColors.admin : AppColors.line,
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppAvatar(
                      initials: d.initials,
                      color: isWinner ? AppColors.admin : AppColors.driver,
                      size: 44),
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: isWinner ? AppColors.admin : AppColors.inkSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('$rank',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(d.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        if (isWinner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.admin,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('BEST',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    Text('${d.vehicle.displayName} • ${d.vehicle.type.label}',
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${candidate.score.round()}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isWinner ? AppColors.admin : AppColors.ink)),
                  const Text('/100',
                      style:
                          TextStyle(color: AppColors.inkSoft, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (candidate.score / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(
                  isWinner ? AppColors.admin : AppColors.driver),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: candidate.reasons
                .map((r) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
