import '../models/app_user.dart';
import '../models/user_role.dart';
import '../static_accounts.dart';

/// Abstraction over authentication. The static implementation backs the demo;
/// swap in an `ApiAuthRepository` (Dio -> Spring Boot) without touching the UI.
abstract class AuthRepository {
  Future<AppUser> login({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> logout();
}

/// Authenticates against the fixed [kStaticAccounts] list — there is no
/// sign-up yet. Email + password must match a known account for the role.
class StaticAuthRepository implements AuthRepository {
  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Please enter your email and password.');
    }

    final normalized = email.trim().toLowerCase();
    final account = staticAccountsForRole(role).cast<StaticAccount?>().firstWhere(
          (a) => a!.user.email.toLowerCase() == normalized,
          orElse: () => null,
        );

    if (account == null) {
      throw AuthException('No ${role.label.toLowerCase()} account found for that email.');
    }
    if (account.password != password) {
      throw const AuthException('Incorrect password. Try again.');
    }
    return account.user;
  }

  @override
  Future<void> logout() async =>
      Future.delayed(const Duration(milliseconds: 200));
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
