import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

class Product {
  final String id;
  final String ownerId;
  final String merchantName;
  final String name;
  final String category;
  final int originalPrice;
  final int discountedPrice;
  final int quantity;
  final int quantityAvailable;
  final DateTime? expiresAt;
  final DateTime? pickupStartAt;
  final DateTime? pickupEndAt;
  final DateTime? createdAt;
  final GeoPoint? location;
  final int interestCount;
  final String status;
  final bool isDeleted;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final String? imageUrl;
  final String? imagePath;
  final bool hasImage;
  final bool hasReservations;
  final Map<String, dynamic>? pricingRecommendation;

  const Product({
    required this.id,
    required this.ownerId,
    required this.merchantName,
    required this.name,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.quantityAvailable,
    required this.expiresAt,
    required this.pickupStartAt,
    required this.pickupEndAt,
    required this.createdAt,
    required this.location,
    required this.interestCount,
    required this.status,
    required this.isDeleted,
    required this.archivedAt,
    required this.deletedAt,
    required this.imageUrl,
    required this.imagePath,
    required this.hasImage,
    required this.hasReservations,
    required this.pricingRecommendation,
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      ownerId: data['ownerId'] as String? ?? '',
      merchantName: data['merchantName'] as String? ?? '',
      name: data['name'] as String? ?? 'Nevtelen termek',
      category: data['category'] as String? ?? 'Ismeretlen kategoria',
      originalPrice: data['originalPrice'] as int? ?? 0,
      discountedPrice: data['discountedPrice'] as int? ?? 0,
      quantity: data['quantity'] as int? ?? 0,
      quantityAvailable:
          data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0,
      expiresAt: _asDate(data['expiresAt']),
      pickupStartAt: _asDate(data['pickupStartAt']),
      pickupEndAt: _asDate(data['pickupEndAt']),
      createdAt: _asDate(data['createdAt']),
      location: data['location'] as GeoPoint?,
      interestCount: data['interestCount'] as int? ?? 0,
      status: data['status'] as String? ?? 'active',
      isDeleted: data['isDeleted'] as bool? ?? false,
      archivedAt: _asDate(data['archivedAt']),
      deletedAt: _asDate(data['deletedAt']),
      imageUrl: data['imageUrl'] as String?,
      imagePath: data['imagePath'] as String?,
      hasImage: data['hasImage'] as bool? ?? false,
      hasReservations: data['hasReservations'] as bool? ?? false,
      pricingRecommendation: data['pricingRecommendation'] is Map
          ? Map<String, dynamic>.from(data['pricingRecommendation'] as Map)
          : null,
    );
  }

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Product.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'merchantName': merchantName,
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'quantityAvailable': quantityAvailable,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'pickupStartAt': pickupStartAt == null
          ? null
          : Timestamp.fromDate(pickupStartAt!),
      'pickupEndAt': pickupEndAt == null
          ? null
          : Timestamp.fromDate(pickupEndAt!),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'location': location,
      'interestCount': interestCount,
      'status': status,
      'isDeleted': isDeleted,
      'archivedAt': archivedAt == null ? null : Timestamp.fromDate(archivedAt!),
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'hasImage': hasImage,
      'hasReservations': hasReservations,
      'pricingRecommendation': pricingRecommendation,
    };
  }
}
