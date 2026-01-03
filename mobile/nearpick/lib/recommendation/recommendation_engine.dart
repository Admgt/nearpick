import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationReason {
  final String code;
  final String label;
  final String? detail;
  final double contribution;

  const RecommendationReason({
    required this.code,
    required this.label,
    this.detail,
    required this.contribution,
  });
}

class RecommendationResult {
  final String productId;
  final Map<String, dynamic> product;
  final double score;
  final List<RecommendationReason> reasons;

  const RecommendationResult({
    required this.productId,
    required this.product,
    required this.score,
    required this.reasons,
  });
}

double _clamp01(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

double favoriteScore(String? category, Set<String> favoriteCategories) {
  if (category == null || category.isEmpty) return 0;
  return favoriteCategories.contains(category) ? 1.0 : 0.0;
}

double recencyScore(DateTime? createdAt) {
  if (createdAt == null) return 0;
  final hours = DateTime.now().difference(createdAt).inMinutes / 60.0;
  if (hours <= 0) return 1.0;
  if (hours >= 72) return 0.0;
  return _clamp01(1.0 - (hours / 72.0));
}

double expiryScore(DateTime? expiresAt) {
  if (expiresAt == null) return 0;
  final hours = expiresAt.difference(DateTime.now()).inMinutes / 60.0;
  if (hours <= 6) return 1.0;
  if (hours >= 48) return 0.0;
  return _clamp01((48.0 - hours) / (48.0 - 6.0));
}

double interestScore(int interestCount) {
  return _clamp01(interestCount / 30.0);
}

String expiryDetail(DateTime expiresAt) {
  final now = DateTime.now();
  final diff = expiresAt.difference(now);
  if (diff.inMinutes <= 0) return 'Hamarosan lejar';
  if (diff.inHours < 1) return 'Lejar ${diff.inMinutes} percen belul';
  if (diff.inHours < 24) return 'Lejar ${diff.inHours} oran belul';
  return 'Lejar: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
}

RecommendationResult scoreProductDoc({
  required String productId,
  required Map<String, dynamic> product,
  required Set<String> favoriteCategories,
  Map<String, int>? implicitCategoryViews,
}) {
  const wFav = 0.40;
  const wExp = 0.30;
  const wRec = 0.13;
  const wInt = 0.05;
  const wImplicit = 0.12;

  final category = product['category'] as String?;
  final expiresAt = _asDate(product['expiresAt']);
  final createdAt = _asDate(product['createdAt']);
  final interestCount = product['interestCount'] as int? ?? 0;
  final implicitViews = implicitCategoryViews ?? const <String, int>{};
  final implicitCount = category == null ? 0 : (implicitViews[category] ?? 0);

  final favScore = favoriteScore(category, favoriteCategories);
  final expScore = expiryScore(expiresAt);
  final recScore = recencyScore(createdAt);
  final intScore = interestScore(interestCount);
  final implicitScore = _clamp01(implicitCount / 10.0);

  final score = _clamp01(
    (wFav * favScore) +
        (wExp * expScore) +
        (wRec * recScore) +
        (wInt * intScore) +
        (wImplicit * implicitScore),
  );

  final reasons = <RecommendationReason>[];
  if (favScore > 0) {
    reasons.add(
      RecommendationReason(
        code: 'FAV_CATEGORY',
        label: 'Kedvenc kategoria',
        detail: category,
        contribution: wFav * favScore,
      ),
    );
  }

  if (expScore > 0.2 && expiresAt != null) {
    reasons.add(
      RecommendationReason(
        code: 'EXPIRING',
        label: 'Hamarosan lejar',
        detail: expiryDetail(expiresAt),
        contribution: wExp * expScore,
      ),
    );
  }

  if (recScore > 0.2 && createdAt != null) {
    final hoursAgo = DateTime.now().difference(createdAt).inMinutes / 60.0;
    final roundedHours = hoursAgo.isNaN ? 0 : hoursAgo.round();
    reasons.add(
      RecommendationReason(
        code: 'RECENT',
        label: 'Uj termek',
        detail: '$roundedHours oraja',
        contribution: wRec * recScore,
      ),
    );
  }

  if (intScore > 0.2) {
    reasons.add(
      RecommendationReason(
        code: 'INTEREST',
        label: 'Erdeklodes',
        detail: '$interestCount erdeklodes',
        contribution: wInt * intScore,
      ),
    );
  }

  if (implicitScore > 0.2) {
    reasons.add(
      RecommendationReason(
        code: 'OFTEN_VIEWED',
        label: 'Gyakran nezett kategoria',
        detail: '$implicitCount megnyitas',
        contribution: wImplicit * implicitScore,
      ),
    );
  }

  reasons.sort((a, b) => b.contribution.compareTo(a.contribution));

  return RecommendationResult(
    productId: productId,
    product: product,
    score: score,
    reasons: reasons,
  );
}
