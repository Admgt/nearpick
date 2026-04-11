import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nearpick/features/consumer/reservation_detail_screen.dart';
import 'package:nearpick/models/reservation.dart';
import 'package:nearpick/models/review.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'consumer can inspect QR pickup data and request refund on cancel',
    (tester) async {
      final reservationController = StreamController<Reservation?>.broadcast();
      final reviewController = StreamController<Review?>.broadcast();
      _CancelCall? cancelCall;

      addTearDown(reservationController.close);
      addTearDown(reviewController.close);

      await tester.pumpWidget(
        _ReservationFlowApp(
          reservationId: 'reservation-1',
          watchReservation: (_) => reservationController.stream,
          watchReview: (_) => reviewController.stream,
          onCancelReservation:
              ({
                required reservationId,
                required reasonCode,
                required reasonNote,
                required refundRequested,
              }) async {
                cancelCall = _CancelCall(
                  reservationId: reservationId,
                  reasonCode: reasonCode,
                  reasonNote: reasonNote,
                  refundRequested: refundRequested,
                );
                reservationController.add(
                  _reservation(
                    status: 'cancelled',
                    cancelReasonCode: reasonCode,
                    cancelReasonNote: reasonNote,
                    refundStatus: refundRequested ? 'pending' : 'not_required',
                  ),
                );
              },
        ),
      );

      reservationController.add(_reservation());
      reviewController.add(null);
      await tester.pumpAndSettle();

      expect(find.text('Bagel box'), findsOneWidget);
      expect(find.text('QR kod az atvetelhez'), findsOneWidget);
      expect(find.text('pickup-token-reservation-1'), findsOneWidget);
      expect(find.text('Mennyiseg: 2 db'), findsOneWidget);

      final cancelButton = find.text('Foglalas lemondasa');
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.text('Foglalas lemondasa'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'Nem erek oda idoben.');
      await tester.tap(find.text('Refund/kompenzacio igenylese'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lemondas rogzitese'));
      await tester.pumpAndSettle();

      expect(cancelCall?.reservationId, 'reservation-1');
      expect(cancelCall?.refundRequested, isTrue);
      expect(cancelCall?.reasonNote, 'Nem erek oda idoben.');
      expect(find.text('Foglalas lemondva.'), findsOneWidget);
      expect(find.text('Status: Lemondva'), findsOneWidget);
      expect(find.text('Refund statusz: Fuggoben'), findsOneWidget);
    },
  );

  testWidgets('consumer can submit a review after completed pickup', (
    tester,
  ) async {
    final reservationController = StreamController<Reservation?>.broadcast();
    final reviewController = StreamController<Review?>.broadcast();
    _ReviewCall? reviewCall;

    addTearDown(reservationController.close);
    addTearDown(reviewController.close);

    await tester.pumpWidget(
      _ReservationFlowApp(
        reservationId: 'reservation-1',
        watchReservation: (_) => reservationController.stream,
        watchReview: (_) => reviewController.stream,
        onSubmitReview:
            ({
              required reservationId,
              required rating,
              required comment,
            }) async {
              reviewCall = _ReviewCall(
                reservationId: reservationId,
                rating: rating,
                comment: comment,
              );
              reviewController.add(
                Review(
                  id: reservationId,
                  reservationId: reservationId,
                  merchantId: 'merchant-1',
                  buyerId: 'buyer-1',
                  buyerDisplayName: 'Demo Buyer',
                  productId: 'product-1',
                  productName: 'Bagel box',
                  rating: rating,
                  comment: comment,
                  createdAt: DateTime(2026, 4, 11, 12),
                ),
              );
            },
      ),
    );

    reservationController.add(_reservation(status: 'completed'));
    reviewController.add(null);
    await tester.pumpAndSettle();

    expect(find.text('Status: Atadva'), findsOneWidget);
    expect(
      find.text('Az atvett rendelest most tudod ertekelni.'),
      findsOneWidget,
    );

    final reviewButton = find.text('Ertekeles irasa');
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Finom, gyors atvetel.');
    await tester.tap(find.text('Kuldes'));
    await tester.pumpAndSettle();

    expect(reviewCall?.reservationId, 'reservation-1');
    expect(reviewCall?.rating, 5);
    expect(reviewCall?.comment, 'Finom, gyors atvetel.');
    expect(find.text('Koszonjuk az ertekelest.'), findsOneWidget);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('Finom, gyors atvetel.'), findsOneWidget);
  });
}

class _ReservationFlowApp extends StatelessWidget {
  final String reservationId;
  final ReservationStreamFactory watchReservation;
  final ReviewStreamFactory watchReview;
  final CancelReservationAction? onCancelReservation;
  final SubmitReviewAction? onSubmitReview;

  const _ReservationFlowApp({
    required this.reservationId,
    required this.watchReservation,
    required this.watchReview,
    this.onCancelReservation,
    this.onSubmitReview,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearPick Reservation Integration Flow Harness',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: ReservationDetailScreen(
        reservationId: reservationId,
        watchReservation: watchReservation,
        watchReview: watchReview,
        onCancelReservation: onCancelReservation,
        onSubmitReview: onSubmitReview,
        showMerchantReviews: false,
      ),
    );
  }
}

Reservation _reservation({
  String status = 'reserved',
  String? cancelReasonCode,
  String cancelReasonNote = '',
  String refundStatus = 'not_requested',
}) {
  final now = DateTime.now();
  final pickupStartAt = now.add(const Duration(hours: 2));
  final pickupEndAt = now.add(const Duration(hours: 4));

  return Reservation(
    id: 'reservation-1',
    productId: 'product-1',
    merchantId: 'merchant-1',
    buyerId: 'buyer-1',
    qty: 2,
    status: status,
    createdAt: now.subtract(const Duration(minutes: 10)),
    expiresAt: pickupEndAt,
    completedAt: status == 'completed' ? now : null,
    cancelledAt: status == 'cancelled' ? now : null,
    expiredAt: null,
    pickupCode: 'ABC123',
    pickupToken: 'pickup-token-reservation-1',
    cancelReasonCode: cancelReasonCode,
    cancelReasonNote: cancelReasonNote,
    cancelledBy: status == 'cancelled' ? 'buyer' : null,
    refundStatus: refundStatus,
    refundRequestedAt: refundStatus == 'pending' ? now : null,
    refundReviewedAt: null,
    refundCompletedAt: null,
    refundReviewedBy: null,
    reviewSubmittedAt: null,
    productSnapshot: {
      'name': 'Bagel box',
      'category': 'Peksutemeny',
      'discountedPrice': 490,
      'originalPrice': 1000,
      'merchantName': 'Demo Bakery',
      'pickupStartAt': pickupStartAt,
      'pickupEndAt': pickupEndAt,
    },
  );
}

class _CancelCall {
  final String reservationId;
  final String reasonCode;
  final String reasonNote;
  final bool refundRequested;

  const _CancelCall({
    required this.reservationId,
    required this.reasonCode,
    required this.reasonNote,
    required this.refundRequested,
  });
}

class _ReviewCall {
  final String reservationId;
  final int rating;
  final String comment;

  const _ReviewCall({
    required this.reservationId,
    required this.rating,
    required this.comment,
  });
}
