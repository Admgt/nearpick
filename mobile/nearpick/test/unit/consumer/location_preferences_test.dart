import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/consumer/location_catalog.dart';
import 'package:nearpick/features/consumer/location_preferences.dart';

void main() {
  test('fromUserData keeps legacy exact home location data', () {
    final preferences = LocationPreferences.fromUserData({
      'homeLocation': const GeoPoint(47.5, 19.0),
      'preferredRadiusKm': 7,
    });

    expect(preferences.locationMode, ConsumerLocationMode.exact);
    expect(preferences.selectedCity, isNull);
    expect(preferences.homeLocation, const GeoPoint(47.5, 19.0));
    expect(preferences.preferredRadiusKm, 7);
    expect(preferences.locationStatusLabel, 'pontos hely');
  });

  test('fromUserData resolves predefined city to approximate location', () {
    final preferences = LocationPreferences.fromUserData({
      'homeLocationMode': 'city',
      'homeLocationCityId': 'szeged',
      'preferredRadiusKm': 5,
    });

    expect(preferences.locationMode, ConsumerLocationMode.city);
    expect(preferences.selectedCity?.id, 'szeged');
    expect(preferences.homeLocation, predefinedCityById('szeged')?.center);
    expect(preferences.locationStatusLabel, 'Szeged (varosi kozelites)');
  });

  test('fromUserData falls back to exact mode for unknown city id', () {
    final preferences = LocationPreferences.fromUserData({
      'homeLocationMode': 'city',
      'homeLocationCityId': 'ismeretlen-varos',
      'homeLocation': const GeoPoint(46.1, 20.1),
    });

    expect(preferences.locationMode, ConsumerLocationMode.exact);
    expect(preferences.selectedCity, isNull);
    expect(preferences.homeLocation, const GeoPoint(46.1, 20.1));
  });
}
