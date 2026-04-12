import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/consumer/offer_filter.dart';

void main() {
  test('shouldIncludeOffer excludes dismissed products', () {
    expect(
      shouldIncludeOffer(
        productId: 'p1',
        product: const {'status': 'active', 'quantityAvailable': 1},
        dismissedProductIds: const {'p1'},
        selectedCategory: 'Osszes',
        allCategoryLabel: 'Osszes',
      ),
      isFalse,
    );
  });

  test('shouldIncludeOffer excludes deleted, inactive, and empty products', () {
    expect(
      shouldIncludeOffer(
        productId: 'p1',
        product: const {
          'isDeleted': true,
          'status': 'active',
          'quantityAvailable': 1,
        },
        dismissedProductIds: const {},
        selectedCategory: 'Osszes',
        allCategoryLabel: 'Osszes',
      ),
      isFalse,
    );
    expect(
      shouldIncludeOffer(
        productId: 'p1',
        product: const {'status': 'archived', 'quantityAvailable': 1},
        dismissedProductIds: const {},
        selectedCategory: 'Osszes',
        allCategoryLabel: 'Osszes',
      ),
      isFalse,
    );
    expect(
      shouldIncludeOffer(
        productId: 'p1',
        product: const {'status': 'active', 'quantityAvailable': 0},
        dismissedProductIds: const {},
        selectedCategory: 'Osszes',
        allCategoryLabel: 'Osszes',
      ),
      isFalse,
    );
  });

  test('shouldIncludeOffer applies category filtering', () {
    expect(
      shouldIncludeOffer(
        productId: 'p1',
        product: const {
          'status': 'active',
          'quantityAvailable': 1,
          'category': 'Pekseg',
        },
        dismissedProductIds: const {},
        selectedCategory: 'Pekseg',
        allCategoryLabel: 'Osszes',
      ),
      isTrue,
    );
    expect(
      shouldIncludeOffer(
        productId: 'p1',
        product: const {
          'status': 'active',
          'quantityAvailable': 1,
          'category': 'Tej',
        },
        dismissedProductIds: const {},
        selectedCategory: 'Pekseg',
        allCategoryLabel: 'Osszes',
      ),
      isFalse,
    );
  });

  test('shouldIncludeOffer matches accented display categories', () {
    expect(
      shouldIncludeOffer(
        productId: 'p1',
        product: const {
          'status': 'active',
          'quantityAvailable': 1,
          'category': 'Egyeb',
        },
        dismissedProductIds: const {},
        selectedCategory: 'Egyéb',
        allCategoryLabel: 'Összes kategória',
      ),
      isTrue,
    );
    expect(
      shouldIncludeOffer(
        productId: 'p2',
        product: const {
          'status': 'active',
          'quantityAvailable': 1,
          'category': 'Peksutemeny',
        },
        dismissedProductIds: const {},
        selectedCategory: 'Péksütemény',
        allCategoryLabel: 'Összes kategória',
      ),
      isTrue,
    );
  });
}
