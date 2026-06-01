import 'user_role.dart';

/// A signed-in user. For driver accounts [driverId] links to a [Driver] record.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final String? driverId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.driverId,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // Ready for the Python API: swap mock data for these later.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        role: UserRole.fromName(json['role'] as String),
        avatarUrl: json['avatar_url'] as String?,
        driverId: json['driver_id']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'avatar_url': avatarUrl,
        'driver_id': driverId,
      };
}
