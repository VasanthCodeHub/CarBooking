import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular avatar that shows a network image when available, otherwise
/// initials on a tinted background. Drop your provided images in by passing
/// [imageUrl] (or an asset via [imageProvider]).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.imageProvider,
    this.size = 44,
    this.color = AppColors.primary,
  });

  final String initials;
  final String? imageUrl;
  final ImageProvider? imageProvider;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final provider = imageProvider ??
        ((imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null);

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: provider == null
          ? Text(
              initials,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
              ),
            )
          : null,
    );
  }
}
