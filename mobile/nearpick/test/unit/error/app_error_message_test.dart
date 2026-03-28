import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
