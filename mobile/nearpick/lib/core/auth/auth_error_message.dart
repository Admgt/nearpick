import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code.contains('requests-from-referer') ||
        message.contains('requests-from-referer')) {
      return 'A bejelentkezes blokkolva van, mert a Firebase API-kulcs nem engedelyezi ezt a localhost cimet.';
    }

    switch (code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
      case 'user-not-found':
        return 'Hibas email vagy jelszo.';
      case 'invalid-email':
        return 'Adj meg egy ervenyes email-cimet.';
      case 'email-already-in-use':
        return 'Ez az email-cim mar hasznalatban van.';
      case 'weak-password':
        return 'A jelszo tul gyenge.';
      case 'network-request-failed':
        return 'Halozati hiba tortent. Probald ujra.';
      case 'too-many-requests':
        return 'Tul sok sikertelen probalkozas tortent. Varj egy kicsit, majd probald ujra.';
    }

    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }

  return error.toString();
}
