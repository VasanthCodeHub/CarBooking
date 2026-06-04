import 'models/app_user.dart';
import 'models/user_role.dart';

/// A static demo login: an [AppUser] plus the password that signs them in.
///
/// These are the only accounts that exist for now — there is no sign-up. The
/// driver accounts link to the backend fleet via [AppUser.driverId] (`d1`..`d6`
/// from the Spring Boot `SeedRunner`); customer ids are stable so each
/// customer's bookings persist in Mongo across logins.
class StaticAccount {
  final AppUser user;
  final String password;
  const StaticAccount({required this.user, required this.password});
}

/// One shared password keeps the demo simple to drive.
const String kDemoPassword = 'demo1234';

const List<StaticAccount> kStaticAccounts = [
  // ── Customers ─────────────────────────────────────────────────────────
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_cust_1',
      name: 'Olivia Bennett',
      email: 'olivia@demo.com',
      phone: '+91 90000 10001',
      role: UserRole.customer,
    ),
  ),
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_cust_2',
      name: 'Noah Carter',
      email: 'noah@demo.com',
      phone: '+91 90000 10002',
      role: UserRole.customer,
    ),
  ),
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_cust_3',
      name: 'Mia Thompson',
      email: 'mia@demo.com',
      phone: '+91 90000 10003',
      role: UserRole.customer,
    ),
  ),

  // ── Drivers (driverId matches the backend fleet d1..d6) ───────────────
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_drv_1',
      name: 'Karthik Raja',
      email: 'karthik@demo.com',
      phone: '+91 98400 11201',
      role: UserRole.driver,
      driverId: 'd1',
    ),
  ),
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_drv_2',
      name: 'Divya Menon',
      email: 'divya@demo.com',
      phone: '+91 98400 11232',
      role: UserRole.driver,
      driverId: 'd2',
    ),
  ),
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_drv_3',
      name: 'Suresh Kumar',
      email: 'suresh@demo.com',
      phone: '+91 98400 11248',
      role: UserRole.driver,
      driverId: 'd3',
    ),
  ),
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_drv_4',
      name: 'Ananya Iyer',
      email: 'ananya@demo.com',
      phone: '+91 98400 11256',
      role: UserRole.driver,
      driverId: 'd4',
    ),
  ),
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_drv_5',
      name: 'Vijay Anand',
      email: 'vijay@demo.com',
      phone: '+91 98400 11267',
      role: UserRole.driver,
      driverId: 'd5',
    ),
  ),
  StaticAccount(
    password: kDemoPassword,
    user: AppUser(
      id: 'u_drv_6',
      name: 'Priya Nair',
      email: 'priya@demo.com',
      phone: '+91 98400 11279',
      role: UserRole.driver,
      driverId: 'd6',
    ),
  ),
];

/// The static accounts available for a given [role] (used by the login picker).
List<StaticAccount> staticAccountsForRole(UserRole role) =>
    kStaticAccounts.where((a) => a.user.role == role).toList();
