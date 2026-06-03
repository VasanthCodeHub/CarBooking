import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/flavor_provider.dart';
import 'data/models/user_role.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [appRoleProvider.overrideWithValue(UserRole.driver)],
      child: const BookingApp(),
    ),
  );
}
