import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodel/auth_viewmodel.dart';

/// Branded splash. In the POC there's no persisted session, so after a short
/// beat we route to login (or straight to the role home if already signed in).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final auth = ref.read(authViewModelProvider);
    context.go(auth.isLoggedIn ? auth.user!.role.homeLocation : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_taxi_rounded,
                    size: 52, color: AppColors.primary),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
              const SizedBox(height: 24),
              Text(
                'RideReserve',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 6),
              Text(
                'Reserve. Auto-dispatch. Ride.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 48),
              SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(
                      Colors.white.withValues(alpha: 0.9)),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
