import 'package:flutter/material.dart';

/// Central color palette for the app. Tweak these to rebrand instantly.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4C5BFF); // electric indigo
  static const Color primaryDark = Color(0xFF2E3AC2);
  static const Color accent = Color(0xFF00D2A8); // teal
  static const Color amber = Color(0xFFFFB020);

  // Surfaces
  static const Color background = Color(0xFFF5F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEFF1FA);
  static const Color ink = Color(0xFF12152B);
  static const Color inkSoft = Color(0xFF5B6079);
  static const Color line = Color(0xFFE4E7F2);

  // Status
  static const Color success = Color(0xFF2BB673);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color info = Color(0xFF3D8BFF);

  // Role accents
  static const Color customer = Color(0xFF4C5BFF);
  static const Color driver = Color(0xFF00B894);
  static const Color admin = Color(0xFF7A5BFF);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF4C5BFF), Color(0xFF7A5BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient driverGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFF7A5BFF), Color(0xFF4C5BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mapGradient = LinearGradient(
    colors: [Color(0xFFE8ECF5), Color(0xFFDDE6F2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
