import 'package:cloud_firestore/cloud_firestore.dart';

import 'location_catalog.dart';

enum ConsumerLocationMode { exact, city }

class LocationPreferences {
  static const double defaultPreferredRadiusKm = 5.0;
  static const double minPreferredRadiusKm = 1.0;
  static const double maxPreferredRadiusKm = 20.0;

  final GeoPoint? homeLocation;
  final double preferredRadiusKm;
  final ConsumerLocationMode locationMode;
  final PredefinedCity? selectedCity;

  const LocationPreferences({
    required this.homeLocation,
    required this.preferredRadiusKm,
    required this.locationMode,
    required this.selectedCity,
  });

  factory LocationPreferences.fromUserData(Map<String, dynamic>? data) {
    final rawRadius = data?['preferredRadiusKm'];
    final radiusKm = rawRadius is num
        ? rawRadius.toDouble()
        : defaultPreferredRadiusKm;
    final storedLocation = data?['homeLocation'] as GeoPoint?;
    final rawMode = data?['homeLocationMode'] as String?;
    final selectedCity = predefinedCityById(
      data?['homeLocationCityId'] as String?,
    );

    final locationMode = rawMode == 'city' && selectedCity != null
        ? ConsumerLocationMode.city
        : ConsumerLocationMode.exact;
    final effectiveLocation = locationMode == ConsumerLocationMode.city
        ? selectedCity!.center
        : storedLocation;

    return LocationPreferences(
      homeLocation: effectiveLocation,
      preferredRadiusKm: normalizePreferredRadiusKm(radiusKm),
      locationMode: locationMode,
      selectedCity: selectedCity,
    );
  }

  bool get hasLocation => homeLocation != null;

  String get locationStatusLabel {
    if (!hasLocation) {
      return 'nincs beallitva';
    }
    if (locationMode == ConsumerLocationMode.city && selectedCity != null) {
      return '${selectedCity!.name} (varosi kozelites)';
    }
    return 'pontos hely';
  }

  static double normalizePreferredRadiusKm(double value) {
    return value.clamp(minPreferredRadiusKm, maxPreferredRadiusKm).toDouble();
  }

  static String radiusLabel(double value) {
    final normalized = normalizePreferredRadiusKm(value);
    if (normalized >= 10) {
      return '${normalized.toStringAsFixed(0)} km';
    }

    if (normalized == normalized.truncateToDouble()) {
      return '${normalized.toStringAsFixed(0)} km';
    }

    return '${normalized.toStringAsFixed(1)} km';
  }
}
