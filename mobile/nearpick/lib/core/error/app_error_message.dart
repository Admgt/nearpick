import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_error_message.dart';
import 'app_exception.dart';

String appErrorMessage(
  Object error, {
  String fallback = 'Varatlan hiba tortent. Probald ujra.',
}) {
  if (error is AppException) {
    final message = _messageForCode(error.code, error.message, fallback);
    return _withContextId(message, error.contextId);
  }

  if (error is FirebaseAuthException) {
    return authErrorMessage(error);
  }

  if (error is FirebaseFunctionsException) {
    final message = _messageForCode(error.code, error.message, fallback);
    return _withContextId(message, contextIdFromDetails(error.details));
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Halozati hiba tortent. Probald ujra.';
      case 'permission-denied':
        return 'Nincs jogosultsagod ehhez a muvelethez.';
      case 'unavailable':
        return 'A szolgaltatas jelenleg nem erheto el. Probald ujra.';
    }
  }

  final sanitized = _sanitizeMessage(error.toString());
  return sanitized ?? fallback;
}

String _messageForCode(String code, String? rawMessage, String fallback) {
  switch (code) {
    case 'unauthenticated':
      return 'Bejelentkezes szukseges.';
    case 'permission-denied':
      return 'Nincs jogosultsagod ehhez a muvelethez.';
    case 'invalid-argument':
      return _sanitizeMessage(rawMessage) ?? 'Ervenytelen adatot adtal meg.';
    case 'failed-precondition':
    case 'not-found':
    case 'already-exists':
    case 'cancelled':
      return _sanitizeMessage(rawMessage) ?? fallback;
    case 'deadline-exceeded':
    case 'resource-exhausted':
    case 'unavailable':
      return 'A szolgaltatas jelenleg nem erheto el. Probald ujra.';
  }

  final sanitized = _sanitizeMessage(rawMessage);
  return sanitized ?? fallback;
}

String _withContextId(String message, String? contextId) {
  final trimmed = contextId?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return message;
  }
  return '$message Hibaazonosito: $trimmed';
}

String? _sanitizeMessage(String? rawMessage) {
  if (rawMessage == null) {
    return null;
  }

  var message = rawMessage.trim();
  if (message.isEmpty) {
    return null;
  }

  for (final prefix in const [
    'Exception:',
    'FirebaseException:',
    'FirebaseFunctionsException:',
    'Bad state:',
    'Hiba:',
  ]) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trim();
    }
  }

  if (message.isEmpty) {
    return null;
  }

  final lower = message.toLowerCase();
  if (lower.contains('bejelentkezett felhaszn')) {
    return 'Bejelentkezes szukseges.';
  }
  if (lower.contains('jogosults')) {
    return 'Nincs jogosultsagod ehhez a muvelethez.';
  }
  if (lower.contains('elfogyott')) {
    return 'Elfogyott.';
  }

  return message;
}
