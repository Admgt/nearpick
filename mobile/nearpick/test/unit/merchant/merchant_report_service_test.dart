import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/services/merchant_report_service.dart';

void main() {
  test(
    'buildReservationsCsv exports reservation, cancellation, and refund data',
    () {
      final csv = buildReservationsCsv([
        {
          'id': 'reservation-1',
          'productId': 'product-1',
          'buyerId': 'buyer-1',
          'status': 'cancelled',
          'qty': 1,
          'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, 10, 0)),
          'expiresAt': Timestamp.fromDate(DateTime(2026, 4, 1, 10, 30)),
          'cancelledAt': Timestamp.fromDate(DateTime(2026, 4, 1, 10, 10)),
          'cancelReasonCode': 'pickup_time_issue',
          'cancelReasonNote': 'Nem erem oda.',
          'refundStatus': 'pending',
          'refundRequestedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 10, 11)),
          'productSnapshot': {
            'name': 'Bagel',
            'category': 'Pekseg',
            'discountedPrice': 500,
            'originalPrice': 1000,
          },
        },
      ], generatedAt: DateTime(2026, 4, 1, 12, 0));

      expect(csv, contains('"reservation_id","product_id","product_name"'));
      expect(csv, contains('"reservation-1","product-1","Bagel","Pekseg"'));
      expect(
        csv,
        contains('"Lemondva"'),
        reason: 'status row should keep raw status',
      );
      expect(csv, contains('"Nem jo az atveteli ido"'));
      expect(csv, contains('"Fuggoben"'));
      expect(csv, contains('"Nem erem oda."'));
      expect(csv, contains('"2026-04-01T12:00:00.000"'));
    },
  );
}
