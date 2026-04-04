import 'package:cloud_firestore/cloud_firestore.dart';

import 'dynamic_pricing.dart';

class NewProductCommand {
  final String name;
  final String category;
  final int originalPrice;
  final int discountedPrice;
  final int quantity;
  final DateTime expiresAt;
  final DateTime pickupStartAt;
  final DateTime pickupEndAt;
  final GeoPoint? location;
  final DynamicPricingRecommendation? pricingRecommendation;

  const NewProductCommand({
    required this.name,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.expiresAt,
    required this.pickupStartAt,
    required this.pickupEndAt,
    required this.location,
    this.pricingRecommendation,
  });
}

String? validateRequiredName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Kotelezo mezo';
  }
  return null;
}

String? validateIntegerField(String? value) {
  if (value == null || int.tryParse(value.trim()) == null) {
    return 'Adj meg egy ervenyes szamot';
  }
  return null;
}

String? validatePositiveQuantity(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed <= 0) {
    return 'Adj meg egy pozitiv szamot';
  }
  return null;
}

String? validateLatitude(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  if (parsed == null || parsed < -90 || parsed > 90) {
    return 'Adj meg -90 es 90 kozotti erteket';
  }
  return null;
}

String? validateLongitude(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  if (parsed == null || parsed < -180 || parsed > 180) {
    return 'Adj meg -180 es 180 kozotti erteket';
  }
  return null;
}

GeoPoint? parseOptionalLocation({
  required String latitudeText,
  required String longitudeText,
}) {
  final latText = latitudeText.trim();
  final lngText = longitudeText.trim();

  if (latText.isEmpty && lngText.isEmpty) {
    return null;
  }
  if (latText.isEmpty || lngText.isEmpty) {
    throw const FormatException('Kerek add meg mindket koordinatat.');
  }

  final latitude = double.tryParse(latText);
  final longitude = double.tryParse(lngText);
  if (latitude == null || longitude == null) {
    throw const FormatException('Adj meg ervenyes szamokat a koordinatakhoz.');
  }
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw const FormatException('A koordinatak tartomanya hibas.');
  }

  return GeoPoint(latitude, longitude);
}

int parsePositiveInt(String text, {required String fieldLabel}) {
  final parsed = int.tryParse(text.trim());
  if (parsed == null || parsed <= 0) {
    throw FormatException('$fieldLabel legyen pozitiv egesz szam.');
  }
  return parsed;
}
