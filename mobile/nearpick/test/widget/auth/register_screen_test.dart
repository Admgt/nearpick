import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/auth/register_screen.dart';

void main() {
  testWidgets('RegisterScreen submits the selected role', (tester) async {
    final submissions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (email, password, displayName, role) async {
            submissions.add('$email|$password|$displayName|$role');
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Merchant User');
    await tester.enterText(
      find.byType(TextField).at(1),
      'merchant@example.com',
    );
    await tester.enterText(find.byType(TextField).at(2), 'secret123');
    await tester.tap(find.byType(RadioListTile<String>).at(1));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(
      submissions.single,
      'merchant@example.com|secret123|Merchant User|merchant',
    );
  });

  testWidgets('RegisterScreen renders registration errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (_, __, ___, ____) async {
            throw Exception('register-failed');
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'User');
    await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'secret123');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('register-failed'), findsOneWidget);
  });
}
