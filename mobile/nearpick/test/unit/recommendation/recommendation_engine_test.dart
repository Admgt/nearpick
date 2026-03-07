import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/recommendation/recommendation_engine.dart';

void main() {
  group('Recommendation engine', () {
    final anchor = DateTime(2026, 3, 6, 12);

    test('favoriteScore returns 1.0 for favorite category', () {
      expect(favoriteScore('Pekseg', {'Pekseg', 'Tej'}), 1.0);
    });

    test('favoriteScore returns 0.0 for non-favorite category', () {
      expect(favoriteScore('Zoldseg', {'Pekseg'}), 0.0);
    });

    test('recencyScore returns 1.0 for freshly created product', () {
      expect(recencyScore(anchor, now: anchor), 1.0);
    });

    test('recencyScore returns 0.0 after 72 hours', () {
      expect(
        recencyScore(anchor.subtract(const Duration(hours: 72)), now: anchor),
        0.0,
      );
    });

    test('expiryScore returns 1.0 inside 6-hour boundary', () {
      expect(
        expiryScore(anchor.add(const Duration(hours: 6)), now: anchor),
        1.0,
      );
    });

    test('expiryScore returns 0.0 at 48 hours or later', () {
      expect(
        expiryScore(anchor.add(const Duration(hours: 48)), now: anchor),
        0.0,
      );
    });

    test('interestScore clamps to 1.0 above the maximum', () {
      expect(interestScore(90), 1.0);
    });

    test('dismiss penalty is stronger for recent dismissals', () {
      final recent = scoreProductDoc(
        productId: 'p1',
        product: {
          'category': 'Pekseg',
          'expiresAt': Timestamp.fromDate(anchor.add(const Duration(hours: 5))),
          'createdAt': Timestamp.fromDate(
            anchor.subtract(const Duration(hours: 1)),
          ),
          'interestCount': 10,
        },
        favoriteCategories: {'Pekseg'},
        now: anchor,
        negativeCategoryDismissals: const {'Pekseg': 2},
        negativeCategoryLastDismissedAt: {
          'Pekseg': Timestamp.fromDate(
            anchor.subtract(const Duration(hours: 2)),
          ),
        },
      );

      final old = scoreProductDoc(
        productId: 'p1',
        product: {
          'category': 'Pekseg',
          'expiresAt': Timestamp.fromDate(anchor.add(const Duration(hours: 5))),
          'createdAt': Timestamp.fromDate(
            anchor.subtract(const Duration(hours: 1)),
          ),
          'interestCount': 10,
        },
        favoriteCategories: {'Pekseg'},
        now: anchor,
        negativeCategoryDismissals: const {'Pekseg': 2},
        negativeCategoryLastDismissedAt: {
          'Pekseg': Timestamp.fromDate(
            anchor.subtract(const Duration(days: 20)),
          ),
        },
      );

      expect(recent.score, lessThan(old.score));
    });

    test('reasons are sorted by contribution descending', () {
      final result = scoreProductDoc(
        productId: 'p1',
        product: {
          'category': 'Pekseg',
          'expiresAt': Timestamp.fromDate(anchor.add(const Duration(hours: 3))),
          'createdAt': Timestamp.fromDate(
            anchor.subtract(const Duration(hours: 1)),
          ),
          'interestCount': 25,
          'location': const GeoPoint(47.5, 19.0),
        },
        favoriteCategories: {'Pekseg'},
        now: anchor,
        userLocation: const GeoPoint(47.5001, 19.0001),
      );

      for (var i = 1; i < result.reasons.length; i++) {
        expect(
          result.reasons[i - 1].contribution,
          greaterThanOrEqualTo(result.reasons[i].contribution),
        );
      }
    });

    test('score is clamped to the 0..1 range with extreme inputs', () {
      final result = scoreProductDoc(
        productId: 'p1',
        product: {
          'category': 'Pekseg',
          'expiresAt': Timestamp.fromDate(
            anchor.add(const Duration(minutes: 1)),
          ),
          'createdAt': Timestamp.fromDate(anchor),
          'interestCount': 999,
          'location': const GeoPoint(47.5, 19.0),
        },
        favoriteCategories: {'Pekseg'},
        now: anchor,
        userLocation: const GeoPoint(47.5, 19.0),
        implicitCategoryViews: const {'Pekseg': 999},
      );

      expect(result.score, inInclusiveRange(0.0, 1.0));
    });

    test('expiryDetail formats minute, hour, and date variants', () {
      expect(
        expiryDetail(anchor.add(const Duration(minutes: 45)), now: anchor),
        contains('percen belul'),
      );
      expect(
        expiryDetail(anchor.add(const Duration(hours: 4)), now: anchor),
        contains('oran belul'),
      );
      expect(
        expiryDetail(anchor.add(const Duration(days: 2)), now: anchor),
        contains('Lejar:'),
      );
    });
  });
}
