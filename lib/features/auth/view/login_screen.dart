import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_role.dart';
import '../viewmodel/auth_viewmodel.dart';

/// Login with a role picker. The selected role decides which experience the
/// user lands in; the router handles the redirect once auth state changes.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _useDemoAccount() {
    _emailController.text = '${_role.name}@demo.com';
    _passwordController.text = 'demo1234';
    setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authViewModelProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
          role: _role,
        );
    // Router redirects on success. Surface errors inline.
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _Header(role: _role),
              const SizedBox(height: 28),
              Text('I am a', style: context.muted),
              const SizedBox(height: 10),
              _RolePicker(
                selected: _role,
                onChanged: (r) {
                  setState(() => _role = r);
                  ref.read(authViewModelProvider.notifier).clearError();
                },
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: context.muted),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Text('Password', style: context.muted),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password is required'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _role.color,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Sign in as ${_role.label}'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton.icon(
                        onPressed: _useDemoAccount,
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: Text('Use ${_role.label} demo account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: role.gradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 18),
        Text('Welcome back', style: context.h1),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue with RideReserve.',
          style: context.muted,
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.15, end: 0, duration: 400.ms);
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.selected, required this.onChanged});
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final role in UserRole.values) ...[
          Expanded(child: _RoleCard(role: role, selected: role == selected, onTap: () => onChanged(role))),
          if (role != UserRole.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.selected, required this.onTap});
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected ? role.gradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.line,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: role.color.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(role.icon,
                color: selected ? Colors.white : AppColors.inkSoft, size: 26),
            const SizedBox(height: 8),
            Text(
              role.label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
