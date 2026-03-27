class ProductInteractionAggregate {
  final int views;
  final int interests;

  const ProductInteractionAggregate({
    required this.views,
    required this.interests,
  });

  double get ctr => views == 0 ? 0.0 : (interests / views) * 100.0;
}

class ProductPricingInsight {
  final int actualPrice;
  final int recommendedPrice;
  final int minimumSuggestedPrice;
  final int maximumSuggestedPrice;
  final int expectedReservations24h;
  final double demandScore;
  final String demandLevel;

  const ProductPricingInsight({
    required this.actualPrice,
    required this.recommendedPrice,
    required this.minimumSuggestedPrice,
    required this.maximumSuggestedPrice,
    required this.expectedReservations24h,
    required this.demandScore,
    required this.demandLevel,
  });

  int get deltaFromRecommendation => actualPrice - recommendedPrice;

  bool get shouldRaisePrice => actualPrice < minimumSuggestedPrice;

  bool get shouldLowerPrice => actualPrice > maximumSuggestedPrice;

  int get deviationPercent {
    if (recommendedPrice <= 0) return 0;
    return ((deltaFromRecommendation / recommendedPrice) * 100).round();
  }
}

class MerchantDashboardMetrics {
  final int activeOffers;
  final int expiredOffers;
  final int soldOutOffers;
  final int viewsToday;
  final int views7d;
  final int interestsToday;
  final int interests7d;
  final double ctr7d;
  final List<MapEntry<String, ProductInteractionAggregate>> topProducts;
  final int pricingCoverageCount;
  final int highDemandOffers;
  final int priceTooLowCount;
  final int priceTooHighCount;
  final double averageDemandScore;
  final double averageRecommendedDiscountPercent;
  final List<MapEntry<String, ProductPricingInsight>> pricingCandidates;

  const MerchantDashboardMetrics({
    required this.activeOffers,
    required this.expiredOffers,
    required this.soldOutOffers,
    required this.viewsToday,
    required this.views7d,
    required this.interestsToday,
    required this.interests7d,
    required this.ctr7d,
    required this.topProducts,
    required this.pricingCoverageCount,
    required this.highDemandOffers,
    required this.priceTooLowCount,
    required this.priceTooHighCount,
    required this.averageDemandScore,
    required this.averageRecommendedDiscountPercent,
    required this.pricingCandidates,
  });
}

MerchantDashboardMetrics buildMerchantDashboardMetrics({
  required List<MapEntry<String, Map<String, dynamic>>> products,
  required List<Map<String, dynamic>> interactions,
  required DateTime now,
}) {
  int activeOffers = 0;
  int expiredOffers = 0;
  int soldOutOffers = 0;

  for (final entry in products) {
    final data = entry.value;
    final quantityAvailable =
        data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0;
    final status = data['status'] as String? ?? 'active';
    final expiresAt = data['expiresAt'] as DateTime?;

    if (status == 'sold_out' || quantityAvailable <= 0) {
      soldOutOffers++;
    }
    if (status == 'expired' || (expiresAt != null && !expiresAt.isAfter(now))) {
      expiredOffers++;
    }
    if (status == 'active' &&
        quantityAvailable > 0 &&
        (expiresAt == null || expiresAt.isAfter(now))) {
      activeOffers++;
    }
  }

  final startToday = DateTime(now.year, now.month, now.day);
  int views7d = 0;
  int interests7d = 0;
  int viewsToday = 0;
  int interestsToday = 0;
  final perProduct = <String, ProductInteractionAggregate>{};
  int pricingCoverageCount = 0;
  int highDemandOffers = 0;
  int priceTooLowCount = 0;
  int priceTooHighCount = 0;
  double demandScoreSum = 0;
  double recommendedDiscountPercentSum = 0;
  final pricingCandidates = <MapEntry<String, ProductPricingInsight>>[];

  for (final interaction in interactions) {
    final type = interaction['type'] as String? ?? '';
    final productId = interaction['productId'] as String? ?? '';
    final createdAt = interaction['createdAt'] as DateTime?;
    if (productId.isEmpty || createdAt == null) {
      continue;
    }

    final current =
        perProduct[productId] ??
        const ProductInteractionAggregate(views: 0, interests: 0);

    if (type == 'view') {
      views7d++;
      perProduct[productId] = ProductInteractionAggregate(
        views: current.views + 1,
        interests: current.interests,
      );
      if (!createdAt.isBefore(startToday)) {
        viewsToday++;
      }
    } else if (type == 'interest') {
      interests7d++;
      perProduct[productId] = ProductInteractionAggregate(
        views: current.views,
        interests: current.interests + 1,
      );
      if (!createdAt.isBefore(startToday)) {
        interestsToday++;
      }
    }
  }

  for (final entry in products) {
    final productId = entry.key;
    final data = entry.value;
    final pricingRecommendation = data['pricingRecommendation'];
    if (pricingRecommendation is! Map) {
      continue;
    }

    final recommendedPrice = pricingRecommendation['recommendedPrice'] as int?;
    final minimumSuggestedPrice =
        pricingRecommendation['minimumSuggestedPrice'] as int?;
    final maximumSuggestedPrice =
        pricingRecommendation['maximumSuggestedPrice'] as int?;
    final expectedReservations24h =
        pricingRecommendation['expectedReservations24h'] as int?;
    final demandScoreValue = pricingRecommendation['demandScore'];
    final demandLevel = pricingRecommendation['demandLevel'] as String?;
    final discountPercentValue = pricingRecommendation['discountPercent'];
    final actualPrice = data['discountedPrice'] as int? ?? 0;
    final status = data['status'] as String? ?? 'active';
    final quantityAvailable =
        data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0;
    final expiresAt = data['expiresAt'] as DateTime?;

    final isActive =
        status == 'active' &&
        quantityAvailable > 0 &&
        (expiresAt == null || expiresAt.isAfter(now));
    if (recommendedPrice == null ||
        minimumSuggestedPrice == null ||
        maximumSuggestedPrice == null ||
        expectedReservations24h == null ||
        demandLevel == null ||
        demandScoreValue is! num ||
        discountPercentValue is! num) {
      continue;
    }

    pricingCoverageCount++;
    final demandScore = demandScoreValue.toDouble();
    demandScoreSum += demandScore;
    recommendedDiscountPercentSum += discountPercentValue.toDouble();
    if (demandLevel == 'high') {
      highDemandOffers++;
    }

    final insight = ProductPricingInsight(
      actualPrice: actualPrice,
      recommendedPrice: recommendedPrice,
      minimumSuggestedPrice: minimumSuggestedPrice,
      maximumSuggestedPrice: maximumSuggestedPrice,
      expectedReservations24h: expectedReservations24h,
      demandScore: demandScore,
      demandLevel: demandLevel,
    );

    if (!isActive) {
      continue;
    }
    if (insight.shouldRaisePrice) {
      priceTooLowCount++;
      pricingCandidates.add(MapEntry(productId, insight));
    } else if (insight.shouldLowerPrice) {
      priceTooHighCount++;
      pricingCandidates.add(MapEntry(productId, insight));
    }
  }

  final topProducts = perProduct.entries.toList()
    ..sort((a, b) => b.value.views.compareTo(a.value.views));
  pricingCandidates.sort((a, b) {
    final aDelta = a.value.deltaFromRecommendation.abs();
    final bDelta = b.value.deltaFromRecommendation.abs();
    return bDelta.compareTo(aDelta);
  });

  return MerchantDashboardMetrics(
    activeOffers: activeOffers,
    expiredOffers: expiredOffers,
    soldOutOffers: soldOutOffers,
    viewsToday: viewsToday,
    views7d: views7d,
    interestsToday: interestsToday,
    interests7d: interests7d,
    ctr7d: views7d == 0 ? 0.0 : (interests7d / views7d) * 100.0,
    topProducts: topProducts.take(5).toList(),
    pricingCoverageCount: pricingCoverageCount,
    highDemandOffers: highDemandOffers,
    priceTooLowCount: priceTooLowCount,
    priceTooHighCount: priceTooHighCount,
    averageDemandScore: pricingCoverageCount == 0
        ? 0.0
        : demandScoreSum / pricingCoverageCount,
    averageRecommendedDiscountPercent: pricingCoverageCount == 0
        ? 0.0
        : recommendedDiscountPercentSum / pricingCoverageCount,
    pricingCandidates: pricingCandidates.take(5).toList(),
  );
}
