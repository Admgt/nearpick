import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  testWidgets('LoginScreen sends a trimmed password reset email', (
    tester,
  ) async {
    String? resetEmail;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onPasswordReset: (email) async {
            resetEmail = email;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('login_email_field')),
      ' user@example.com ',
    );
    await tester.tap(find.byKey(const ValueKey('open_password_reset_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('password_reset_email_field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('password_reset_email_field')),
      ' reset@example.com ',
    );
    await tester.tap(
      find.byKey(const ValueKey('password_reset_submit_button')),
    );
    await tester.pumpAndSettle();

    expect(resetEmail, 'reset@example.com');
    expect(find.textContaining('jelszo-visszaallitasi email'), findsOneWidget);
  });

  testWidgets('LoginScreen renders password reset errors in the dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onPasswordReset: (_) async {
            throw FirebaseAuthException(code: 'invalid-email');
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open_password_reset_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('password_reset_email_field')),
      'rossz-email',
    );
    await tester.tap(
      find.byKey(const ValueKey('password_reset_submit_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adj meg egy ervenyes email-cimet.'), findsOneWidget);
  });
}
