import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/auth/auth_error_message.dart';

void main() {
  test('maps blocked localhost referer errors to a clear message', () {
    final error = FirebaseAuthException(
      code: 'unknown',
      message:
          '[firebase_auth/requests-from-referer-http://localhost:49914-are-blocked.] Error',
    );

    expect(
      authErrorMessage(error),
      'A bejelentkezes blokkolva van, mert a Firebase API-kulcs nem engedelyezi ezt a localhost cimet.',
    );
  });

  test('maps invalid credential errors to a user-facing message', () {
    final error = FirebaseAuthException(code: 'invalid-credential');

    expect(authErrorMessage(error), 'Hibas email vagy jelszo.');
  });

  test('maps invalid email errors to a user-facing message', () {
    final error = FirebaseAuthException(code: 'invalid-email');

    expect(authErrorMessage(error), 'Adj meg egy ervenyes email-cimet.');
  });

  test('falls back to the original exception text for unknown errors', () {
    final error = Exception('unexpected');

    expect(authErrorMessage(error), 'Exception: unexpected');
  });
}
