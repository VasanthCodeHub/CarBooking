import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:booking/app.dart';
import 'package:booking/data/flavor_provider.dart';
import 'package:booking/data/models/user_role.dart';

void main() {
  testWidgets('App boots for the customer flavor', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRoleProvider.overrideWithValue(UserRole.customer)],
        child: const BookingApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(BookingApp), findsOneWidget);
  });
}
