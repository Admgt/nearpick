import 'dart:math' as math;

class MerchantMarketSnapshot {
  final int views7d;
  final int interests7d;
  final int dismissals7d;
  final int activeCategoryOffers;
  final double averageDiscountRatio;

  const MerchantMarketSnapshot({
    required this.views7d,
    required this.interests7d,
    required this.dismissals7d,
    required this.activeCategoryOffers,
    required this.averageDiscountRatio,
  });

  double get ctr => views7d == 0 ? 0.0 : interests7d / views7d;
}

class PricingReason {
  final String label;
  final String detail;
  final double weight;

  const PricingReason({
    required this.label,
    required this.detail,
    required this.weight,
  });
}

class DynamicPricingRecommendation {
  final int recommendedPrice;
  final int minimumSuggestedPrice;
  final int maximumSuggestedPrice;
  final int discountPercent;
  final double demandScore;
  final String demandLevel;
  final int expectedReservations24h;
  final MerchantMarketSnapshot marketSnapshot;
  final List<PricingReason> reasons;

  const DynamicPricingRecommendation({
    required this.recommendedPrice,
    required this.minimumSuggestedPrice,
    required this.maximumSuggestedPrice,
    required this.discountPercent,
    required this.demandScore,
    required this.demandLevel,
    required this.expectedReservations24h,
    required this.marketSnapshot,
    required this.reasons,
  });

  Map<String, dynamic> toProductSnapshot() {
    return {
      'recommendedPrice': recommendedPrice,
      'minimumSuggestedPrice': minimumSuggestedPrice,
      'maximumSuggestedPrice': maximumSuggestedPrice,
      'discountPercent': discountPercent,
      'demandScore': demandScore,
      'demandLevel': demandLevel,
      'expectedReservations24h': expectedReservations24h,
      'views7d': marketSnapshot.views7d,
      'interests7d': marketSnapshot.interests7d,
      'dismissals7d': marketSnapshot.dismissals7d,
      'activeCategoryOffers': marketSnapshot.activeCategoryOffers,
      'averageDiscountPercent': (marketSnapshot.averageDiscountRatio * 100)
          .round(),
    };
  }
}

String demandLevelLabel(String demandLevel) {
  switch (demandLevel) {
    case 'high':
      return 'magas';
    case 'medium':
      return 'kozepes';
    default:
      return 'alacsony';
  }
}

double _clamp01(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

double _rangeProgress(double value, double min, double max) {
  if (value <= min) return 0;
  if (value >= max) return 1;
  return (value - min) / (max - min);
}

int _roundPrice(int value) {
  if (value <= 200) {
    return math.max(50, ((value / 10).round()) * 10);
  }
  return math.max(50, ((value / 50).round()) * 50);
}

MerchantMarketSnapshot buildMerchantMarketSnapshot({
  required String category,
  required List<Map<String, dynamic>> interactions,
  required List<Map<String, dynamic>> products,
  required DateTime now,
}) {
  int views7d = 0;
  int interests7d = 0;
  int dismissals7d = 0;
  int activeCategoryOffers = 0;
  double totalDiscountRatio = 0;
  int discountSamples = 0;

  for (final interaction in interactions) {
    final interactionCategory = interaction['category'] as String? ?? '';
    if (interactionCategory != category) {
      continue;
    }

    final type = interaction['type'] as String? ?? '';
    if (type == 'view') {
      views7d++;
    } else if (type == 'interest') {
      interests7d++;
    } else if (type == 'dismiss') {
      dismissals7d++;
    }
  }

  for (final product in products) {
    final productCategory = product['category'] as String? ?? '';
    if (productCategory != category) {
      continue;
    }

    final status = product['status'] as String? ?? 'active';
    final isDeleted = product['isDeleted'] == true;
    final quantityAvailable =
        product['quantityAvailable'] as int? ??
        product['quantity'] as int? ??
        0;
    final expiresAt = product['expiresAt'] as DateTime?;

    if (!isDeleted &&
        status == 'active' &&
        quantityAvailable > 0 &&
        (expiresAt == null || expiresAt.isAfter(now))) {
      activeCategoryOffers++;
    }

    final originalPrice = product['originalPrice'] as int? ?? 0;
    final discountedPrice = product['discountedPrice'] as int? ?? 0;
    if (originalPrice > 0 &&
        discountedPrice > 0 &&
        discountedPrice < originalPrice) {
      totalDiscountRatio += 1.0 - (discountedPrice / originalPrice);
      discountSamples++;
    }
  }

  return MerchantMarketSnapshot(
    views7d: views7d,
    interests7d: interests7d,
    dismissals7d: dismissals7d,
    activeCategoryOffers: activeCategoryOffers,
    averageDiscountRatio: discountSamples == 0
        ? 0.22
        : totalDiscountRatio / discountSamples,
  );
}

DynamicPricingRecommendation buildDynamicPricingRecommendation({
  required int originalPrice,
  required int quantity,
  required DateTime expiresAt,
  required MerchantMarketSnapshot marketSnapshot,
  DateTime? now,
}) {
  final referenceNow = now ?? DateTime.now();
  final remainingMinutes = math.max(
    0,
    expiresAt.difference(referenceNow).inMinutes,
  );
  final hoursToExpiry = remainingMinutes / 60.0;

  final urgencyPressure = 1.0 - _rangeProgress(hoursToExpiry, 6, 72);
  final stockPressure = _clamp01(quantity / 10.0);
  final viewsScore = _clamp01(marketSnapshot.views7d / 50.0);
  final interestsScore = _clamp01(marketSnapshot.interests7d / 15.0);
  final dismissScore = _clamp01(marketSnapshot.dismissals7d / 10.0);
  final ctrScore = _clamp01(marketSnapshot.ctr / 0.35);
  final competitionScore = _clamp01(marketSnapshot.activeCategoryOffers / 8.0);

  final demandScore = _clamp01(
    (0.28 * viewsScore) +
        (0.28 * interestsScore) +
        (0.18 * ctrScore) +
        (0.12 * urgencyPressure) -
        (0.08 * dismissScore) -
        (0.06 * competitionScore),
  );

  final rawDiscountRatio = _clamp01(
    0.08 +
        (0.30 * marketSnapshot.averageDiscountRatio) +
        (0.22 * urgencyPressure) +
        (0.14 * stockPressure) +
        (0.10 * competitionScore) -
        (0.12 * demandScore) -
        (0.06 * ctrScore) +
        (0.08 * dismissScore),
  );
  final discountRatio = rawDiscountRatio < 0.08
      ? 0.08
      : rawDiscountRatio > 0.60
      ? 0.60
      : rawDiscountRatio;

  final recommendedPrice = _roundPrice(
    math.max(50, (originalPrice * (1 - discountRatio)).round()),
  );
  final minimumSuggestedPrice = _roundPrice(
    math.max(50, (recommendedPrice * 0.9).round()),
  );
  final maximumSuggestedPrice = _roundPrice(
    math.min<int>(originalPrice, (recommendedPrice * 1.1).round()),
  );

  final demandLevel = demandScore >= 0.68
      ? 'high'
      : demandScore >= 0.35
      ? 'medium'
      : 'low';
  final expectedReservations24h = math.max(
    0,
    (demandScore * 4.5 + ctrScore * 1.5 - dismissScore + 0.5).round(),
  );

  final reasons = <PricingReason>[
    PricingReason(
      label: 'Lejarati nyomas',
      detail: hoursToExpiry < 24
          ? 'Kevesebb mint 24 ora van hatra.'
          : 'A termek meg nem azonnal jar le.',
      weight: urgencyPressure,
    ),
    PricingReason(
      label: 'Kategoria kereslet',
      detail:
          '${marketSnapshot.views7d} megtekintes, ${marketSnapshot.interests7d} erdeklodes az utolso 7 napban.',
      weight: demandScore,
    ),
    PricingReason(
      label: 'Aktiv kinalat',
      detail:
          '${marketSnapshot.activeCategoryOffers} aktiv ajanlat van ebben a kategoriaban.',
      weight: competitionScore,
    ),
    PricingReason(
      label: 'Elutasitasok',
      detail:
          '${marketSnapshot.dismissals7d} elutasitas erkezett ugyanebben a kategoriaban.',
      weight: dismissScore,
    ),
  ]..sort((a, b) => b.weight.compareTo(a.weight));

  return DynamicPricingRecommendation(
    recommendedPrice: recommendedPrice,
    minimumSuggestedPrice: minimumSuggestedPrice,
    maximumSuggestedPrice: maximumSuggestedPrice,
    discountPercent: (discountRatio * 100).round(),
    demandScore: demandScore,
    demandLevel: demandLevel,
    expectedReservations24h: expectedReservations24h,
    marketSnapshot: marketSnapshot,
    reasons: reasons.take(3).toList(),
  );
}
