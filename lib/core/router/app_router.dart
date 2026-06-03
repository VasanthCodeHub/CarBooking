import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/flavor_provider.dart';
import '../../data/models/user_role.dart';
import '../../features/admin/view/admin_shell.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/splash_screen.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../features/customer/view/book_ride_screen.dart';
import '../../features/customer/view/customer_shell.dart';
import '../../features/customer/view/trip_detail_screen.dart';
import '../../features/driver/view/driver_ride_detail_screen.dart';
import '../../features/driver/view/driver_shell.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final appRole = ref.watch(appRoleProvider);
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);
      final loc = state.matchedLocation;

      if (loc == '/splash') return null;

      if (!auth.isLoggedIn) return loc == '/login' ? null : '/login';

      final home = appRole.homeLocation;
      if (loc == '/login') return home;
      if (!loc.startsWith(home)) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      if (appRole == UserRole.customer)
        GoRoute(
          path: '/customer',
          builder: (_, __) => const CustomerShell(),
          routes: [
            GoRoute(path: 'book', builder: (_, __) => const BookRideScreen()),
            GoRoute(
              path: 'trip/:id',
              builder: (_, state) =>
                  TripDetailScreen(bookingId: state.pathParameters['id']!),
            ),
          ],
        ),
      if (appRole == UserRole.driver)
        GoRoute(
          path: '/driver',
          builder: (_, __) => const DriverShell(),
          routes: [
            GoRoute(
              path: 'ride/:id',
              builder: (_, state) =>
                  DriverRideDetailScreen(bookingId: state.pathParameters['id']!),
            ),
          ],
        ),
      if (appRole == UserRole.admin)
        GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
    ],
  );
});
