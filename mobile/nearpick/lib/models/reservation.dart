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
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? expiredAt;
  final String pickupCode;
  final String pickupToken;
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
    required this.completedAt,
    required this.cancelledAt,
    required this.expiredAt,
    required this.pickupCode,
    required this.pickupToken,
    required this.productSnapshot,
  });

  factory Reservation.fromMap(String id, Map<String, dynamic> data) {
    DateTime? asDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Reservation(
      id: id,
      productId: data['productId'] as String? ?? '',
      merchantId: data['merchantId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      qty: data['qty'] as int? ?? 1,
      status: data['status'] as String? ?? 'reserved',
      createdAt: asDate(data['createdAt']),
      expiresAt: asDate(data['expiresAt']),
      completedAt: asDate(data['completedAt']),
      cancelledAt: asDate(data['cancelledAt']),
      expiredAt: asDate(data['expiredAt']),
      pickupCode: data['pickupCode'] as String? ?? '',
      pickupToken: data['pickupToken'] as String? ?? '',
      productSnapshot: Map<String, dynamic>.from(
        data['productSnapshot'] as Map? ?? {},
      ),
    );
  }

  factory Reservation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Reservation.fromMap(doc.id, data);
  }

  bool get isReserved => status == 'reserved';

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  bool get isExpired => status == 'expired';
}
