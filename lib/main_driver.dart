import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'data/flavor_provider.dart';
import 'data/models/user_role.dart';
import 'data/providers.dart';
import 'data/repositories/api_booking_repository.dart';
import 'data/repositories/api_driver_repository.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        appRoleProvider.overrideWithValue(UserRole.driver),
        // Driver flavor talks to the real Spring Boot API.
        driverRepositoryProvider
            .overrideWith((ref) => ApiDriverRepository(ref.watch(dioProvider))),
        bookingRepositoryProvider
            .overrideWith((ref) => ApiBookingRepository(ref.watch(dioProvider))),
      ],
      child: const BookingApp(),
    ),
  );
}
