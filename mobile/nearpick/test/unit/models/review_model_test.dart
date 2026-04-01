import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/models/review.dart';

void main() {
  test('Review.fromMap uses fallbacks for missing fields', () {
    final review = Review.fromMap('review-1', const {});

    expect(review.id, 'review-1');
    expect(review.reservationId, '');
    expect(review.merchantId, '');
    expect(review.buyerId, '');
    expect(review.productId, '');
    expect(review.rating, 0);
    expect(review.comment, '');
    expect(review.createdAt, isNull);
  });
}
