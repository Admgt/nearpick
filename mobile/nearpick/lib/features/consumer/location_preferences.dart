import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPreferences {
  static const double defaultPreferredRadiusKm = 5.0;
  static const double minPreferredRadiusKm = 1.0;
  static const double maxPreferredRadiusKm = 20.0;

  final GeoPoint? homeLocation;
  final double preferredRadiusKm;

  const LocationPreferences({
    required this.homeLocation,
    required this.preferredRadiusKm,
  });

  factory LocationPreferences.fromUserData(Map<String, dynamic>? data) {
    final rawRadius = data?['preferredRadiusKm'];
    final radiusKm = rawRadius is num
        ? rawRadius.toDouble()
        : defaultPreferredRadiusKm;

    return LocationPreferences(
      homeLocation: data?['homeLocation'] as GeoPoint?,
      preferredRadiusKm: normalizePreferredRadiusKm(radiusKm),
    );
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
