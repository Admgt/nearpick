import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String productId;
  final String merchantId;
  final String buyerId;
  final int qty;
  final String status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String pickupCode;
  final Map<String, dynamic> productSnapshot;

  const Reservation({
    required this.id,
    required this.productId,
    required this.merchantId,
    required this.buyerId,
    required this.qty,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.pickupCode,
    required this.productSnapshot,
  });

  factory Reservation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    DateTime? asDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Reservation(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      merchantId: data['merchantId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      qty: data['qty'] as int? ?? 1,
      status: data['status'] as String? ?? 'reserved',
      createdAt: asDate(data['createdAt']),
      expiresAt: asDate(data['expiresAt']),
      pickupCode: data['pickupCode'] as String? ?? '',
      productSnapshot: Map<String, dynamic>.from(
        data['productSnapshot'] as Map? ?? {},
      ),
    );
  }
}
