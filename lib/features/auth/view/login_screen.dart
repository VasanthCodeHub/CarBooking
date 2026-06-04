import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/flavor_provider.dart';
import '../../../data/static_accounts.dart';
import '../viewmodel/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDemoAccount() async {
    FocusScope.of(context).unfocus();
    final role = ref.read(appRoleProvider);
    final accounts = staticAccountsForRole(role);

    final picked = await showModalBottomSheet<StaticAccount>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: role.color, size: 20),
                    const SizedBox(width: 8),
                    Text('Demo ${role.label.toLowerCase()} accounts',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              for (final a in accounts)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role.color.withValues(alpha: 0.15),
                    child: Text(a.user.initials,
                        style: TextStyle(
                            color: role.color, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(a.user.name),
                  subtitle: Text(a.user.email),
                  onTap: () => Navigator.pop(context, a),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return;
    _emailController.text = picked.user.email;
    _passwordController.text = picked.password;
    setState(() {});
    await _submit();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final role = ref.read(appRoleProvider);
    await ref.read(authViewModelProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
          role: role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final role = ref.watch(appRoleProvider);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: role.gradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child:
                        const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 18),
                  Text('Welcome back', style: context.h1),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue as ${role.label}.',
                    style: context.muted,
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.15, end: 0, duration: 400.ms),
              const SizedBox(height: 36),
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password is required' : null,
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
                          backgroundColor: role.color,
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
                            : Text('Sign in as ${role.label}'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton.icon(
                        onPressed: auth.isLoading ? null : _pickDemoAccount,
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: Text('Use a ${role.label.toLowerCase()} demo account'),
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
