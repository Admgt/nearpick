class ProductInteractionAggregate {
  final int views;
  final int interests;

  const ProductInteractionAggregate({
    required this.views,
    required this.interests,
  });

  double get ctr => views == 0 ? 0.0 : (interests / views) * 100.0;
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

  final topProducts = perProduct.entries.toList()
    ..sort((a, b) => b.value.views.compareTo(a.value.views));

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
  );
}
