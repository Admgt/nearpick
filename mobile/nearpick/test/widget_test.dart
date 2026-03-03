import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/recommendation/recommendation_engine.dart';

void main() {
  test('favoriteScore returns 1.0 for favorite category', () {
    final score = favoriteScore('Pekseg', {'Pekseg', 'Tejtermek'});
    expect(score, 1.0);
  });

  test('favoriteScore returns 0.0 for null or non-favorite category', () {
    expect(favoriteScore(null, {'Pekseg'}), 0.0);
    expect(favoriteScore('Zoldseg', {'Pekseg'}), 0.0);
  });

  test('interestScore is clamped to [0,1]', () {
    expect(interestScore(0), 0.0);
    expect(interestScore(15), closeTo(0.5, 0.0001));
    expect(interestScore(100), 1.0);
  });

  test('recencyScore decays over time and reaches 0 after 72 hours', () {
    final now = DateTime.now();
    final fresh = now.subtract(const Duration(hours: 1));
    final old = now.subtract(const Duration(hours: 80));

    expect(recencyScore(fresh), greaterThan(0.0));
    expect(recencyScore(old), 0.0);
  });

  test('expiryScore is high near expiry and 0 far in the future', () {
    final soon = DateTime.now().add(const Duration(hours: 2));
    final far = DateTime.now().add(const Duration(hours: 72));

    expect(expiryScore(soon), greaterThan(0.8));
    expect(expiryScore(far), 0.0);
  });
}
