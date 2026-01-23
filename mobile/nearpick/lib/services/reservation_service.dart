import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> reserveProduct({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final productRef = _db.collection('products').doc(productId);
    final reservationRef = _db.collection('reservations').doc();

    // TODO: Move this transaction to a Cloud Function for stricter security.
    await _db.runTransaction((tx) async {
      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        throw Exception('A termek nem talalhato.');
      }
      final data = productSnap.data() as Map<String, dynamic>? ?? {};
      final status = data['status'] as String? ?? 'active';
      final isDeleted = data['isDeleted'] as bool? ?? false;
      if (status != 'active' || isDeleted) {
        throw Exception('A termek mar nem elerheto.');
      }

      final quantityAvailable =
          data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0;
      if (quantityAvailable <= 0) {
        throw Exception('Elfogyott');
      }

      final newQty = quantityAvailable - 1;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 30));
      final pickupCode = _generatePickupCode(6);

      final ownerId = data['ownerId'] as String? ?? '';
      final productSnapshot = <String, dynamic>{
        'name': data['name'] as String? ?? '',
        'discountedPrice': data['discountedPrice'] as int? ?? 0,
        'originalPrice': data['originalPrice'] as int? ?? 0,
        'imageUrl': data['imageUrl'] as String?,
        'expiresAt': data['expiresAt'],
        'category': data['category'] as String? ?? '',
      };

      final updates = <String, dynamic>{
        'quantityAvailable': newQty,
        'quantity': newQty,
      };
      if (newQty == 0) {
        updates['status'] = 'sold_out';
        updates['soldOutAt'] = FieldValue.serverTimestamp();
      }

      tx.update(productRef, updates);

      tx.set(reservationRef, {
        'productId': productId,
        'merchantId': ownerId,
        'buyerId': user.uid,
        'qty': 1,
        'status': 'reserved',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'pickupCode': pickupCode,
        'productSnapshot': productSnapshot,
      });

      if (ownerId.isNotEmpty) {
        final statsRef = _db.collection('merchantStats').doc(ownerId);
        final statsUpdate = <String, dynamic>{
          'reservedCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (newQty == 0) {
          statsUpdate['soldOutCount'] = FieldValue.increment(1);
        }
        tx.set(statsRef, statsUpdate, SetOptions(merge: true));
      }
    });

    return reservationRef.id;
  }

  Future<void> completeReservation({required String reservationId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final reservationRef = _db.collection('reservations').doc(reservationId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(reservationRef);
      if (!snap.exists) {
        throw Exception('A foglalas nem talalhato.');
      }
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final merchantId = data['merchantId'] as String? ?? '';
      if (merchantId.isEmpty || merchantId != user.uid) {
        throw Exception('Nincs jogosultsag a foglalashoz.');
      }
      final status = data['status'] as String? ?? '';
      if (status != 'reserved') return;

      tx.update(reservationRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      final statsRef = _db.collection('merchantStats').doc(merchantId);
      tx.set(
        statsRef,
        {
          'completedCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  String _generatePickupCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
