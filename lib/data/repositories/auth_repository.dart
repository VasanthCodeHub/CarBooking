import '../mock/mock_data.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Abstraction over authentication. The mock implementation backs the POC;
/// swap in an `ApiAuthRepository` (Dio -> Python) without touching the UI.
abstract class AuthRepository {
  Future<AppUser> login({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> logout();
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Please enter your email and password.');
    }

    // In the POC the chosen role wins. We try to match a seeded demo account
    // for that role so the screens show a real name/profile.
    final match = MockData.users.where((u) => u.role == role).cast<AppUser?>().firstWhere(
          (u) => u!.email.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => null,
        );
    if (match != null) return match;

    final template = MockData.users.firstWhere((u) => u.role == role);
    final name = _nameFromEmail(email);
    return AppUser(
      id: 'u_${role.name}_${email.hashCode.abs()}',
      name: name,
      email: email.trim(),
      phone: template.phone,
      role: role,
      driverId: role == UserRole.driver ? template.driverId : null,
    );
  }

  @override
  Future<void> logout() async =>
      Future.delayed(const Duration(milliseconds: 200));

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ').trim();
    if (local.isEmpty) return 'Guest User';
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
