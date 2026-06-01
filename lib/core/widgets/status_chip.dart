import 'package:flutter/material.dart';

/// A small rounded status pill (booking status, driver status, etc.).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              height: 7,
              width: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: filled ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
