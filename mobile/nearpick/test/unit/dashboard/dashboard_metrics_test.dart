import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/merchant/dashboard_metrics.dart';

void main() {
  final anchor = DateTime(2026, 3, 6, 12);

  test('buildMerchantDashboardMetrics aggregates offer statuses', () {
    final metrics = buildMerchantDashboardMetrics(
      products: [
        MapEntry('p1', {
          'status': 'active',
          'quantityAvailable': 2,
          'expiresAt': anchor.add(const Duration(days: 1)),
        }),
        MapEntry('p2', {
          'status': 'sold_out',
          'quantityAvailable': 0,
          'expiresAt': anchor.add(const Duration(days: 1)),
        }),
        MapEntry('p3', {
          'status': 'active',
          'quantityAvailable': 1,
          'expiresAt': anchor.subtract(const Duration(minutes: 1)),
        }),
      ],
      interactions: const [],
      now: anchor,
    );

    expect(metrics.activeOffers, 1);
    expect(metrics.soldOutOffers, 1);
    expect(metrics.expiredOffers, 1);
  });

  test(
    'buildMerchantDashboardMetrics calculates views, interests, and CTR',
    () {
      final metrics = buildMerchantDashboardMetrics(
        products: const [],
        interactions: [
          {'type': 'view', 'productId': 'p1', 'createdAt': anchor},
          {'type': 'view', 'productId': 'p1', 'createdAt': anchor},
          {'type': 'interest', 'productId': 'p1', 'createdAt': anchor},
          {
            'type': 'view',
            'productId': 'p2',
            'createdAt': anchor.subtract(const Duration(days: 1)),
          },
        ],
        now: anchor,
      );

      expect(metrics.viewsToday, 2);
      expect(metrics.views7d, 3);
      expect(metrics.interestsToday, 1);
      expect(metrics.ctr7d, closeTo(33.333, 0.01));
      expect(metrics.topProducts.first.key, 'p1');
    },
  );

  test('buildMerchantDashboardMetrics extracts pricing insights', () {
    final metrics = buildMerchantDashboardMetrics(
      products: [
        MapEntry('p1', {
          'status': 'active',
          'quantityAvailable': 2,
          'discountedPrice': 900,
          'expiresAt': anchor.add(const Duration(days: 1)),
          'pricingRecommendation': {
            'recommendedPrice': 700,
            'minimumSuggestedPrice': 650,
            'maximumSuggestedPrice': 750,
            'expectedReservations24h': 2,
            'demandScore': 0.82,
            'demandLevel': 'high',
            'discountPercent': 30,
          },
        }),
        MapEntry('p2', {
          'status': 'active',
          'quantityAvailable': 1,
          'discountedPrice': 450,
          'expiresAt': anchor.add(const Duration(days: 1)),
          'pricingRecommendation': {
            'recommendedPrice': 600,
            'minimumSuggestedPrice': 550,
            'maximumSuggestedPrice': 650,
            'expectedReservations24h': 1,
            'demandScore': 0.45,
            'demandLevel': 'medium',
            'discountPercent': 25,
          },
        }),
        MapEntry('p3', {
          'status': 'archived',
          'quantityAvailable': 0,
          'discountedPrice': 500,
          'expiresAt': anchor.subtract(const Duration(days: 1)),
        }),
      ],
      interactions: const [],
      now: anchor,
    );

    expect(metrics.pricingCoverageCount, 2);
    expect(metrics.highDemandOffers, 1);
    expect(metrics.priceTooHighCount, 1);
    expect(metrics.priceTooLowCount, 1);
    expect(metrics.averageDemandScore, closeTo(0.635, 0.001));
    expect(metrics.averageRecommendedDiscountPercent, closeTo(27.5, 0.001));
    expect(metrics.pricingCandidates, hasLength(2));
    expect(metrics.pricingCandidates.first.key, 'p1');
    expect(metrics.pricingCandidates.first.value.shouldLowerPrice, isTrue);
  });
}
