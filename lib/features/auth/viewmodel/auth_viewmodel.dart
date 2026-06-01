import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/user_role.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/auth_repository.dart';

/// Immutable auth state exposed to the views and the router.
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// MVVM ViewModel for authentication. The view calls [login]/[logout];
/// the router reacts to the resulting state.
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(email: email, password: password, role: role);
      state = AuthState(user: user, isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
