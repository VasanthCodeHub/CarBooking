import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/view/admin_shell.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/splash_screen.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../features/customer/view/book_ride_screen.dart';
import '../../features/customer/view/customer_shell.dart';
import '../../features/customer/view/trip_detail_screen.dart';
import '../../features/driver/view/driver_ride_detail_screen.dart';
import '../../features/driver/view/driver_shell.dart';

/// Bridges the Riverpod auth state to go_router's [GoRouter.refreshListenable]
/// so the router re-evaluates redirects whenever auth changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);
      final loc = state.matchedLocation;

      // Let the splash screen run its own intro + navigation.
      if (loc == '/splash') return null;

      final loggedIn = auth.isLoggedIn;
      if (!loggedIn) return loc == '/login' ? null : '/login';

      // Logged in: keep users inside their role's area.
      final home = auth.user!.role.homeLocation;
      if (loc == '/login') return home;
      if (!loc.startsWith(home)) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/customer',
        builder: (_, __) => const CustomerShell(),
        routes: [
          GoRoute(
            path: 'book',
            builder: (_, __) => const BookRideScreen(),
          ),
          GoRoute(
            path: 'trip/:id',
            builder: (_, state) =>
                TripDetailScreen(bookingId: state.pathParameters['id']!),
          ),
        ],
      ),
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
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminShell(),
      ),
    ],
  );
});
