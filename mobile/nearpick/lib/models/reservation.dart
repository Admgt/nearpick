import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

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
  final String? cancelReasonCode;
  final String cancelReasonNote;
  final String? cancelledBy;
  final String refundStatus;
  final DateTime? refundRequestedAt;
  final DateTime? refundReviewedAt;
  final DateTime? refundCompletedAt;
  final String? refundReviewedBy;
  final DateTime? reviewSubmittedAt;
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
    required this.cancelReasonCode,
    required this.cancelReasonNote,
    required this.cancelledBy,
    required this.refundStatus,
    required this.refundRequestedAt,
    required this.refundReviewedAt,
    required this.refundCompletedAt,
    required this.refundReviewedBy,
    required this.reviewSubmittedAt,
    required this.productSnapshot,
  });

  factory Reservation.fromMap(String id, Map<String, dynamic> data) {
    return Reservation(
      id: id,
      productId: data['productId'] as String? ?? '',
      merchantId: data['merchantId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      qty: data['qty'] as int? ?? 1,
      status: data['status'] as String? ?? 'reserved',
      createdAt: _asDate(data['createdAt']),
      expiresAt: _asDate(data['expiresAt']),
      completedAt: _asDate(data['completedAt']),
      cancelledAt: _asDate(data['cancelledAt']),
      expiredAt: _asDate(data['expiredAt']),
      pickupCode: data['pickupCode'] as String? ?? '',
      pickupToken: data['pickupToken'] as String? ?? '',
      cancelReasonCode: data['cancelReasonCode'] as String?,
      cancelReasonNote: data['cancelReasonNote'] as String? ?? '',
      cancelledBy: data['cancelledBy'] as String?,
      refundStatus: data['refundStatus'] as String? ?? 'not_requested',
      refundRequestedAt: _asDate(data['refundRequestedAt']),
      refundReviewedAt: _asDate(data['refundReviewedAt']),
      refundCompletedAt: _asDate(data['refundCompletedAt']),
      refundReviewedBy: data['refundReviewedBy'] as String?,
      reviewSubmittedAt: _asDate(data['reviewSubmittedAt']),
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

  bool get hasRefundRequest =>
      refundStatus != 'not_requested' && refundStatus != 'not_required';

  bool get hasReview => reviewSubmittedAt != null;

  DateTime? get pickupStartAt => _asDate(productSnapshot['pickupStartAt']);

  DateTime? get pickupEndAt => _asDate(productSnapshot['pickupEndAt']);

  String get merchantName => productSnapshot['merchantName'] as String? ?? '';
}
