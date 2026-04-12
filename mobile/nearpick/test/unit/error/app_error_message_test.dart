import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/error/app_exception.dart';
import 'package:nearpick/core/error/app_error_message.dart';

void main() {
  test('strips generic exception prefix', () {
    expect(
      appErrorMessage(Exception('A foglalas nem sikerult.')),
      'A foglalas nem sikerult.',
    );
  });

  test('maps failed-precondition Firebase functions errors', () {
    final error = FirebaseFunctionsException(
      code: 'failed-precondition',
      message: 'Elfogyott',
    );

    expect(appErrorMessage(error), 'Elfogyott.');
  });

  test('preserves detailed failed-precondition Firebase functions errors', () {
    final error = FirebaseFunctionsException(
      code: 'failed-precondition',
      message: 'Ervenytelen atveteli kod.',
    );

    expect(appErrorMessage(error), 'Ervenytelen atveteli kod.');
  });

  test('preserves quantity-specific failed-precondition errors', () {
    final error = FirebaseFunctionsException(
      code: 'failed-precondition',
      message: 'A kert mennyiseg nem erheto el.',
    );

    expect(appErrorMessage(error), 'A kert mennyiseg nem erheto el.');
  });

  test('normalizes sign-in required messages from generic exceptions', () {
    expect(
      appErrorMessage(Exception('Nincs bejelentkezett felhasznÃ¡lÃ³.')),
      'Bejelentkezes szukseges.',
    );
  });

  test('normalizes permission messages from generic exceptions', () {
    expect(
      appErrorMessage(Exception('Nincs jogosultsÃ¡g.')),
      'Nincs jogosultsagod ehhez a muvelethez.',
    );
  });

  test('adds context id from app exceptions', () {
    const error = AppException(
      code: 'failed-precondition',
      message: 'A termek mar nem erheto el.',
      contextId: 'ctx-123',
    );

    expect(
      appErrorMessage(error),
      'A termek mar nem erheto el. Hibaazonosito: ctx-123',
    );
  });

  test('adds context id from Firebase functions details', () {
    final error = FirebaseFunctionsException(
      code: 'not-found',
      message: 'A termek nem talalhato.',
      details: {'contextId': 'ctx-456'},
    );

    expect(
      appErrorMessage(error),
      'A termek nem talalhato. Hibaazonosito: ctx-456',
    );
  });
}
