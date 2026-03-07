import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen submits trimmed credentials', (tester) async {
    String? submittedEmail;
    String? submittedPassword;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (email, password) async {
            submittedEmail = email;
            submittedPassword = password;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), ' user@example.com ');
    await tester.enterText(find.byType(TextField).at(1), ' secret ');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'user@example.com');
    expect(submittedPassword, 'secret');
  });

  testWidgets('LoginScreen renders the login error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (_, __) async {
            throw Exception('auth-failed');
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('auth-failed'), findsOneWidget);
  });
}
