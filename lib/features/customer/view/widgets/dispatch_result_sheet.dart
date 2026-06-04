import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../data/models/dispatch.dart';

/// Shown right after a reservation is created. Plays a short "scanning" beat,
/// then reveals the auto-matched driver and *why* the engine picked them.
class DispatchResultSheet extends StatefulWidget {
  const DispatchResultSheet({super.key, required this.result});
  final DispatchResult result;

  @override
  State<DispatchResultSheet> createState() => _DispatchResultSheetState();
}

class _DispatchResultSheetState extends State<DispatchResultSheet> {
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            child: _scanning
                ? const _Scanning()
                : _Result(result: widget.result),
          ),
        ),
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scaleXY(begin: 0.8, end: 1.2, duration: 900.ms)
                .fadeOut(),
            const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 40),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Auto-dispatching…',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        const Text('Matching you with the best available driver',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.result});
  final DispatchResult result;

  @override
  Widget build(BuildContext context) {
    final winner = result.winner;
    if (winner == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.hourglass_top_rounded,
              color: AppColors.amber, size: 48),
          const SizedBox(height: 12),
          const Text('Reservation received',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          const Text(
            'No driver is free this second — we’ll auto-assign one the moment '
            'a driver becomes available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 18),
          _doneButton(context),
        ],
      );
    }

    final d = winner.driver;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18),
                SizedBox(width: 6),
                Text('Driver auto-assigned',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 18),
        Row(
          children: [
            AppAvatar(initials: d.initials, color: AppColors.driver, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
                  Text('${d.vehicle.displayName} • ${d.vehicle.plate}',
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 13)),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.amber, size: 18),
                    Text(d.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                Text('${winner.etaMinutes.round()} min away',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Why this driver',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('match ${winner.score.round()}/100',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...winner.reasons.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 15, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(r,
                              style: const TextStyle(fontSize: 12.5))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _doneButton(context),
      ],
    );
  }

  Widget _doneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('View trip'),
      ),
    );
  }
}
