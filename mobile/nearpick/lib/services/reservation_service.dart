import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/error/app_exception.dart';

class ReservationService {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  ReservationService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  }) : _functions = functions ?? FirebaseFunctions.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance;

  Future<String> reserveProduct({
    required String productId,
    int quantity = 1,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Bejelentkezes szukseges.',
      );
    }
    if (quantity <= 0) {
      throw const AppException(
        code: 'invalid-argument',
        message: 'Ervenytelen foglalasi mennyiseg.',
      );
    }

    try {
      final callable = _functions.httpsCallable('reserveProduct');
      final response = await callable.call(
        withClientContextId({'productId': productId, 'quantity': quantity}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final reservationId = data['reservationId'] as String?;
      if (reservationId == null || reservationId.isEmpty) {
        throw const AppException(
          code: 'internal',
          message: 'A foglalas letrejott, de nincs reservationId.',
        );
      }
      return reservationId;
    } on FirebaseFunctionsException catch (e) {
      throw AppException.fromFunctions(e, fallback: 'A foglalas nem sikerult.');
    }
  }

  Future<void> completeReservation({
    required String reservationId,
    required String pickupInput,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Bejelentkezes szukseges.',
      );
    }

    try {
      final callable = _functions.httpsCallable('completeReservation');
      await callable.call(
        withClientContextId({
          'reservationId': reservationId,
          'pickupInput': pickupInput,
        }),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AppException.fromFunctions(
        e,
        fallback: 'A foglalas nem teljesitheto.',
      );
    }
  }

  Future<void> cancelReservation({
    required String reservationId,
    required String reasonCode,
    String reasonNote = '',
    bool refundRequested = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Bejelentkezes szukseges.',
      );
    }

    try {
      final callable = _functions.httpsCallable('cancelReservation');
      await callable.call(
        withClientContextId({
          'reservationId': reservationId,
          'reasonCode': reasonCode,
          'reasonNote': reasonNote,
          'refundRequested': refundRequested,
        }),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AppException.fromFunctions(
        e,
        fallback: 'A foglalas nem mondhato le.',
      );
    }
  }

  Future<void> updateRefundStatus({
    required String reservationId,
    required String refundStatus,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Bejelentkezes szukseges.',
      );
    }

    try {
      final callable = _functions.httpsCallable('updateRefundStatus');
      await callable.call(
        withClientContextId({
          'reservationId': reservationId,
          'refundStatus': refundStatus,
        }),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AppException.fromFunctions(
        e,
        fallback: 'A refund statusz nem modosithato.',
      );
    }
  }

  Future<void> submitReview({
    required String reservationId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Bejelentkezes szukseges.',
      );
    }

    try {
      final callable = _functions.httpsCallable('submitReview');
      await callable.call(
        withClientContextId({
          'reservationId': reservationId,
          'rating': rating,
          'comment': comment,
        }),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AppException.fromFunctions(
        e,
        fallback: 'Az ertekeles nem kuldheto be.',
      );
    }
  }

  Future<String?> findReservationIdByPickupCode({
    required String merchantId,
    required String pickupCode,
  }) async {
    final query = await _db
        .collection('reservations')
        .where('merchantId', isEqualTo: merchantId)
        .where('pickupCode', isEqualTo: pickupCode)
        .limit(10)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    query.docs.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aReserved = (aData['status'] as String? ?? '') == 'reserved';
      final bReserved = (bData['status'] as String? ?? '') == 'reserved';
      if (aReserved != bReserved) {
        return aReserved ? -1 : 1;
      }

      final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate();
      final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate();
      if (aCreatedAt == null || bCreatedAt == null) {
        return 0;
      }
      return bCreatedAt.compareTo(aCreatedAt);
    });

    return query.docs.first.id;
  }
}
