import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/auth/register_screen.dart';

void main() {
  testWidgets('RegisterScreen submits the selected role', (tester) async {
    final submissions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (email, password, displayName, role, companyName) async {
            submissions.add('$email|$password|$displayName|$role|$companyName');
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('register_name_field')),
      'Merchant User',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_email_field')),
      'merchant@example.com',
    );
    await tester.tap(find.byType(RadioListTile<String>).at(1));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('register_company_name_field')),
      'Penny',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('register_submit_button')));
    await tester.pumpAndSettle();

    expect(
      submissions.single,
      'merchant@example.com|secret123|Merchant User|merchant|Penny',
    );
  });

  testWidgets('RegisterScreen renders registration errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (_, __, ___, ____, _____) async {
            throw Exception('register-failed');
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('register_name_field')),
      'User',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('register-failed'), findsOneWidget);
  });

  testWidgets('RegisterScreen requires company name for merchants', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('register_name_field')),
      'Merchant User',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_email_field')),
      'merchant@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_password_field')),
      'secret123',
    );
    await tester.tap(find.byType(RadioListTile<String>).at(1));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('register_submit_button')));
    await tester.pump();

    expect(find.textContaining('ceg nevet'), findsOneWidget);
  });
}
