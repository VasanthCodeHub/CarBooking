import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/splash_screen.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../theme/app_colors.dart';

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
      // NOTE: these three are temporary placeholders replaced in Layers 3–5.
      GoRoute(
        path: '/customer',
        builder: (_, __) => const _RoleHomePlaceholder(role: UserRole.customer),
      ),
      GoRoute(
        path: '/driver',
        builder: (_, __) => const _RoleHomePlaceholder(role: UserRole.driver),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const _RoleHomePlaceholder(role: UserRole.admin),
      ),
    ],
  );
});

/// Temporary landing shown after login until the real role shells land.
class _RoleHomePlaceholder extends ConsumerWidget {
  const _RoleHomePlaceholder({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: role.gradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(role.icon, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                '${role.label} area',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Signed in as ${user?.name ?? ''}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 28),
              FilledButton.tonal(
                onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.ink,
                ),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
