import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The three user types the app supports. The login key/role decides which
/// experience (shell) a signed-in user lands in.
enum UserRole {
  customer,
  driver,
  admin;

  String get label => switch (this) {
        UserRole.customer => 'Customer',
        UserRole.driver => 'Driver',
        UserRole.admin => 'Admin',
      };

  String get tagline => switch (this) {
        UserRole.customer => 'Book & schedule rides',
        UserRole.driver => 'Drive & earn',
        UserRole.admin => 'Dispatch & manage fleet',
      };

  IconData get icon => switch (this) {
        UserRole.customer => Icons.person_rounded,
        UserRole.driver => Icons.directions_car_rounded,
        UserRole.admin => Icons.dashboard_rounded,
      };

  Color get color => switch (this) {
        UserRole.customer => AppColors.customer,
        UserRole.driver => AppColors.driver,
        UserRole.admin => AppColors.admin,
      };

  LinearGradient get gradient => switch (this) {
        UserRole.customer => AppColors.brandGradient,
        UserRole.driver => AppColors.driverGradient,
        UserRole.admin => AppColors.adminGradient,
      };

  /// Used by the router to resolve the home location for a role.
  String get homeLocation => switch (this) {
        UserRole.customer => '/customer',
        UserRole.driver => '/driver',
        UserRole.admin => '/admin',
      };

  static UserRole fromName(String name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => UserRole.customer);
}
