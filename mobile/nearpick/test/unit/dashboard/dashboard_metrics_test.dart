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
}
