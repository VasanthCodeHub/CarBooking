import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/user_role.dart';

/// Holds the role this flavor of the app is built for.
/// Each main_*.dart overrides this with its fixed role.
final appRoleProvider = Provider<UserRole>((ref) => UserRole.customer);
