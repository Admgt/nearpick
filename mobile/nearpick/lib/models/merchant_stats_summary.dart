import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantStatsSummary {
  final String merchantId;
  final double averageRating;
  final int reviewCount;
  final int reservedCount;
  final int completedCount;

  const MerchantStatsSummary({
    required this.merchantId,
    required this.averageRating,
    required this.reviewCount,
    required this.reservedCount,
    required this.completedCount,
  });

  factory MerchantStatsSummary.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return MerchantStatsSummary(
      merchantId: doc.id,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      reservedCount: data['reservedCount'] as int? ?? 0,
      completedCount: data['completedCount'] as int? ?? 0,
    );
  }

  String get averageRatingLabel =>
      reviewCount == 0 ? '-' : averageRating.toStringAsFixed(1);
}
