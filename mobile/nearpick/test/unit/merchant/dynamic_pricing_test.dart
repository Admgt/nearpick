import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/merchant/dynamic_pricing.dart';

void main() {
  final anchor = DateTime(2026, 3, 27, 12);

  test('buildMerchantMarketSnapshot aggregates category signals', () {
    final snapshot = buildMerchantMarketSnapshot(
      category: 'Peksutemeny',
      interactions: const [
        {'category': 'Peksutemeny', 'type': 'view'},
        {'category': 'Peksutemeny', 'type': 'view'},
        {'category': 'Peksutemeny', 'type': 'interest'},
        {'category': 'Peksutemeny', 'type': 'dismiss'},
        {'category': 'Tejtermek', 'type': 'view'},
      ],
      products: [
        {
          'category': 'Peksutemeny',
          'status': 'active',
          'quantityAvailable': 2,
          'originalPrice': 1000,
          'discountedPrice': 800,
          'expiresAt': anchor.add(const Duration(hours: 5)),
        },
        {
          'category': 'Peksutemeny',
          'status': 'archived',
          'quantityAvailable': 0,
          'originalPrice': 1000,
          'discountedPrice': 700,
          'expiresAt': anchor.subtract(const Duration(hours: 1)),
        },
      ],
      now: anchor,
    );

    expect(snapshot.views7d, 2);
    expect(snapshot.interests7d, 1);
    expect(snapshot.dismissals7d, 1);
    expect(snapshot.activeCategoryOffers, 1);
    expect(snapshot.averageDiscountRatio, closeTo(0.25, 0.001));
  });

  test('high demand recommends a higher price than weak demand', () {
    final strongDemand = buildDynamicPricingRecommendation(
      originalPrice: 1000,
      quantity: 2,
      expiresAt: anchor.add(const Duration(hours: 24)),
      marketSnapshot: const MerchantMarketSnapshot(
        views7d: 50,
        interests7d: 16,
        dismissals7d: 0,
        activeCategoryOffers: 1,
        averageDiscountRatio: 0.15,
      ),
      now: anchor,
    );
    final weakDemand = buildDynamicPricingRecommendation(
      originalPrice: 1000,
      quantity: 2,
      expiresAt: anchor.add(const Duration(hours: 24)),
      marketSnapshot: const MerchantMarketSnapshot(
        views7d: 3,
        interests7d: 0,
        dismissals7d: 4,
        activeCategoryOffers: 5,
        averageDiscountRatio: 0.25,
      ),
      now: anchor,
    );

    expect(strongDemand.demandLevel, 'high');
    expect(weakDemand.demandLevel, 'low');
    expect(
      strongDemand.recommendedPrice,
      greaterThan(weakDemand.recommendedPrice),
    );
  });

  test('urgent, high-stock products get a deeper recommended discount', () {
    final urgent = buildDynamicPricingRecommendation(
      originalPrice: 1500,
      quantity: 8,
      expiresAt: anchor.add(const Duration(hours: 8)),
      marketSnapshot: const MerchantMarketSnapshot(
        views7d: 8,
        interests7d: 1,
        dismissals7d: 2,
        activeCategoryOffers: 4,
        averageDiscountRatio: 0.20,
      ),
      now: anchor,
    );
    final relaxed = buildDynamicPricingRecommendation(
      originalPrice: 1500,
      quantity: 2,
      expiresAt: anchor.add(const Duration(hours: 72)),
      marketSnapshot: const MerchantMarketSnapshot(
        views7d: 8,
        interests7d: 1,
        dismissals7d: 2,
        activeCategoryOffers: 4,
        averageDiscountRatio: 0.20,
      ),
      now: anchor,
    );

    expect(urgent.discountPercent, greaterThan(relaxed.discountPercent));
    expect(urgent.recommendedPrice, lessThan(relaxed.recommendedPrice));
  });
}
