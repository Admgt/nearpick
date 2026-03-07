import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/utils/geo_utils.dart';

void main() {
  test('haversineKm returns 0 for identical points', () {
    expect(GeoUtils.haversineKm(47.5, 19.0, 47.5, 19.0), closeTo(0.0, 0.0001));
  });

  test('haversineKm is symmetric', () {
    final ab = GeoUtils.haversineKm(47.5, 19.0, 47.6, 19.1);
    final ba = GeoUtils.haversineKm(47.6, 19.1, 47.5, 19.0);
    expect(ab, closeTo(ba, 0.0001));
  });
}
