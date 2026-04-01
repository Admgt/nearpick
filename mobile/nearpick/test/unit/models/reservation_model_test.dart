import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/models/reservation.dart';

void main() {
  test('Reservation.fromMap uses fallbacks for missing fields', () {
    final reservation = Reservation.fromMap('r1', const {});

    expect(reservation.id, 'r1');
    expect(reservation.productId, '');
    expect(reservation.status, 'reserved');
    expect(reservation.qty, 1);
    expect(reservation.pickupToken, '');
    expect(reservation.cancelReasonCode, isNull);
    expect(reservation.cancelReasonNote, '');
    expect(reservation.refundStatus, 'not_requested');
    expect(reservation.reviewSubmittedAt, isNull);
    expect(reservation.hasReview, isFalse);
    expect(reservation.productSnapshot, isEmpty);
  });
}
