import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String reservationId;
  final String merchantId;
  final String buyerId;
  final String productId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.reservationId,
    required this.merchantId,
    required this.buyerId,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> data) {
    DateTime? asDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Review(
      id: id,
      reservationId: data['reservationId'] as String? ?? '',
      merchantId: data['merchantId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: asDate(data['createdAt']),
    );
  }

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Review.fromMap(doc.id, data);
  }
}
