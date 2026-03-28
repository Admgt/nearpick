import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/reservation/pickup_token.dart';

void main() {
  test('parsePickupToken parses QR token payloads', () {
    final parsed = parsePickupToken('NEARPICK:reservation-42:ABC123');

    expect(parsed.reservationId, 'reservation-42');
    expect(parsed.pickupCode, 'ABC123');
  });

  test('parsePickupToken falls back to plain pickup codes', () {
    final parsed = parsePickupToken('ABC123');

    expect(parsed.reservationId, isNull);
    expect(parsed.pickupCode, 'ABC123');
  });
}
