import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/geo_utils.dart';

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
  final double? distanceKm;
  final double? preferredRadiusKm;
  final bool isWithinPreferredRadius;

  const RecommendationResult({
    required this.productId,
    required this.product,
    required this.score,
    required this.reasons,
    required this.distanceKm,
    required this.preferredRadiusKm,
    required this.isWithinPreferredRadius,
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

double recencyScore(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) return 0;
  final referenceNow = now ?? DateTime.now();
  final hours = referenceNow.difference(createdAt).inMinutes / 60.0;
  if (hours <= 0) return 1.0;
  if (hours >= 72) return 0.0;
  return _clamp01(1.0 - (hours / 72.0));
}

double expiryScore(DateTime? expiresAt, {DateTime? now}) {
  if (expiresAt == null) return 0;
  final referenceNow = now ?? DateTime.now();
  final hours = expiresAt.difference(referenceNow).inMinutes / 60.0;
  if (hours <= 6) return 1.0;
  if (hours >= 48) return 0.0;
  return _clamp01((48.0 - hours) / (48.0 - 6.0));
}

double interestScore(int interestCount) {
  return _clamp01(interestCount / 30.0);
}

String distanceLabelKm(double distanceKm) {
  if (distanceKm < 1.0) {
    return '${(distanceKm * 1000).round()} m';
  }
  if (distanceKm >= 10.0) {
    return '${distanceKm.toStringAsFixed(0)} km';
  }
  return '${distanceKm.toStringAsFixed(1)} km';
}

double proximityScore(double? distanceKm, {required double preferredRadiusKm}) {
  if (distanceKm == null) return 0;

  final effectiveWindowKm = math.max(8.0, preferredRadiusKm * 2.5);
  if (distanceKm >= effectiveWindowKm) {
    return 0;
  }

  return _clamp01(1.0 - (distanceKm / effectiveWindowKm));
}

double radiusAlignmentScore(
  double? distanceKm, {
  required double preferredRadiusKm,
}) {
  if (distanceKm == null || distanceKm > preferredRadiusKm) {
    return 0;
  }

  return _clamp01(1.0 - (distanceKm / preferredRadiusKm));
}

double outsideRadiusPenalty(
  double? distanceKm, {
  required double preferredRadiusKm,
}) {
  if (distanceKm == null) return 0;

  final overflowKm = distanceKm - preferredRadiusKm;
  if (overflowKm <= 0) {
    return 0;
  }

  final overflowRatio = overflowKm / math.max(preferredRadiusKm, 1.0);
  return math.min(0.12, overflowRatio * 0.08);
}

String expiryDetail(DateTime expiresAt, {DateTime? now}) {
  final referenceNow = now ?? DateTime.now();
  final diff = expiresAt.difference(referenceNow);
  if (diff.inMinutes <= 0) return 'Hamarosan lejar';
  if (diff.inHours < 1) return 'Lejar ${diff.inMinutes} percen belul';
  if (diff.inHours < 24) return 'Lejar ${diff.inHours} oran belul';
  return 'Lejar: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
}

String _relativeTimeLabel(DateTime? date, DateTime now) {
  if (date == null) return 'ismeretlen';
  final diff = now.difference(date);
  if (diff.inMinutes <= 1) return 'most';
  if (diff.inHours < 1) return '${diff.inMinutes} perce';
  if (diff.inHours < 24) return '${diff.inHours} oraja';
  return '${diff.inDays} napja';
}

RecommendationResult scoreProductDoc({
  required String productId,
  required Map<String, dynamic> product,
  required Set<String> favoriteCategories,
  DateTime? now,
  GeoPoint? userLocation,
  double preferredRadiusKm = 5.0,
  Map<String, int>? implicitCategoryViews,
  Map<String, Timestamp>? implicitLastViewedAt,
  Map<String, int>? negativeCategoryDismissals,
  Map<String, Timestamp>? negativeCategoryLastDismissedAt,
}) {
  const wFav = 0.30;
  const wExp = 0.23;
  const wRec = 0.12;
  const wInt = 0.05;
  const wImplicit = 0.10;
  const wDist = 0.10;
  const wRadius = 0.10;
  const halfLifeDays = 7.0;
  final normalizedPreferredRadiusKm = preferredRadiusKm.clamp(1.0, 20.0);

  final category = product['category'] as String?;
  final expiresAt = _asDate(product['expiresAt']);
  final createdAt = _asDate(product['createdAt']);
  final interestCount = product['interestCount'] as int? ?? 0;
  final productLoc = product['location'] as GeoPoint?;
  final implicitViews = implicitCategoryViews ?? const <String, int>{};
  final implicitCount = category == null ? 0 : (implicitViews[category] ?? 0);
  final implicitLastViewed =
      implicitLastViewedAt ?? const <String, Timestamp>{};
  final lastViewedAt = category == null
      ? null
      : _asDate(implicitLastViewed[category]);

  final referenceNow = now ?? DateTime.now();
  final ageDays = lastViewedAt == null
      ? 999.0
      : (referenceNow.difference(lastViewedAt).inMinutes / 60.0 / 24.0).clamp(
          0.0,
          999.0,
        );
  final lambda = math.log(2) / halfLifeDays;
  final decayFactor = math.exp(-lambda * ageDays);
  final effectiveCount = implicitCount * decayFactor;

  final favScore = favoriteScore(category, favoriteCategories);
  final expScore = expiryScore(expiresAt, now: referenceNow);
  final recScore = recencyScore(createdAt, now: referenceNow);
  final intScore = interestScore(interestCount);
  final implicitScore = _clamp01(effectiveCount / 10.0);
  double? distanceKm;
  double distanceScore = 0;
  double radiusScore = 0;
  double distancePenalty = 0;
  if (userLocation != null && productLoc != null) {
    distanceKm = GeoUtils.haversineKm(
      userLocation.latitude,
      userLocation.longitude,
      productLoc.latitude,
      productLoc.longitude,
    );
    distanceScore = proximityScore(
      distanceKm,
      preferredRadiusKm: normalizedPreferredRadiusKm,
    );
    radiusScore = radiusAlignmentScore(
      distanceKm,
      preferredRadiusKm: normalizedPreferredRadiusKm,
    );
    distancePenalty = outsideRadiusPenalty(
      distanceKm,
      preferredRadiusKm: normalizedPreferredRadiusKm,
    );
  }

  final negativeDismissals =
      negativeCategoryDismissals ?? const <String, int>{};
  final negativeLastDismissed =
      negativeCategoryLastDismissedAt ?? const <String, Timestamp>{};
  final dismissCount = category == null
      ? 0
      : (negativeDismissals[category] ?? 0);
  final lastDismissedAt = category == null
      ? null
      : _asDate(negativeLastDismissed[category]);
  final daysSinceDismiss = dismissCount == 0
      ? 0.0
      : (lastDismissedAt == null
                ? 0.0
                : (referenceNow.difference(lastDismissedAt).inMinutes /
                      60.0 /
                      24.0))
            .clamp(0.0, 999.0);
  final dismissDecay = dismissCount == 0
      ? 0.0
      : math.exp(-daysSinceDismiss / 7.0);
  final dismissPenaltyBase = dismissCount == 0
      ? 0.0
      : math.min(0.25, 0.08 * dismissCount);
  final dismissPenalty = dismissPenaltyBase * dismissDecay;

  final score = _clamp01(
    (wFav * favScore) +
        (wExp * expScore) +
        (wRec * recScore) +
        (wInt * intScore) +
        (wImplicit * implicitScore) +
        (wDist * distanceScore) +
        (wRadius * radiusScore) -
        dismissPenalty -
        distancePenalty,
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
        detail: expiryDetail(expiresAt, now: referenceNow),
        contribution: wExp * expScore,
      ),
    );
  }

  if (recScore > 0.2 && createdAt != null) {
    final hoursAgo = referenceNow.difference(createdAt).inMinutes / 60.0;
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
    final ageDetail = () {
      if (lastViewedAt == null) {
        return 'utoljara: 999 napja';
      }
      final hoursAgo = referenceNow.difference(lastViewedAt).inMinutes / 60.0;
      if (hoursAgo < 1) return 'utoljara: ma';
      if (hoursAgo < 24) return 'utoljara: ${hoursAgo.round()} oraja';
      return 'utoljara: ${ageDays.round()} napja';
    }();
    reasons.add(
      RecommendationReason(
        code: 'OFTEN_VIEWED',
        label: 'Gyakran nezett kategoria',
        detail:
            '$implicitCount megnyitas • $ageDetail • hatas: ${effectiveCount.toStringAsFixed(1)}',
        contribution: wImplicit * implicitScore,
      ),
    );
  }

  if (dismissCount > 0 && dismissPenalty > 0.005) {
    final lastDismissedText = _relativeTimeLabel(lastDismissedAt, referenceNow);
    reasons.add(
      RecommendationReason(
        code: 'DISMISSED_CATEGORY',
        label: 'Korabban elutasitott kategoria',
        detail:
            '$dismissCount elutasitas - utoljara: $lastDismissedText - hatas: ${(dismissPenalty * 100).toStringAsFixed(0)}%',
        contribution: -dismissPenalty,
      ),
    );
  }

  if (distanceScore > 0.2 && distanceKm != null) {
    reasons.add(
      RecommendationReason(
        code: 'NEARBY',
        label: 'Közel van',
        detail: distanceLabelKm(distanceKm),
        contribution: wDist * distanceScore,
      ),
    );
  }

  if (radiusScore > 0.1 && distanceKm != null) {
    reasons.add(
      RecommendationReason(
        code: 'INSIDE_RADIUS',
        label: 'Belefer a sugarba',
        detail:
            '${distanceLabelKm(distanceKm)} / ${distanceLabelKm(normalizedPreferredRadiusKm)}',
        contribution: wRadius * radiusScore,
      ),
    );
  }

  if (distancePenalty > 0.005 && distanceKm != null) {
    reasons.add(
      RecommendationReason(
        code: 'OUTSIDE_RADIUS',
        label: 'Kivul esik a sugaron',
        detail:
            '${distanceLabelKm(distanceKm)} - cel: ${distanceLabelKm(normalizedPreferredRadiusKm)}',
        contribution: -distancePenalty,
      ),
    );
  }

  reasons.sort((a, b) => b.contribution.compareTo(a.contribution));

  return RecommendationResult(
    productId: productId,
    product: product,
    score: score,
    reasons: reasons,
    distanceKm: distanceKm,
    preferredRadiusKm: distanceKm == null ? null : normalizedPreferredRadiusKm,
    isWithinPreferredRadius:
        distanceKm != null && distanceKm <= normalizedPreferredRadiusKm,
  );
}
