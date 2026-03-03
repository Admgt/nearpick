import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final int originalPrice;
  final int discountedPrice;
  final int quantity;
  final int quantityAvailable;
  final DateTime? expiresAt;
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

  const Product({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.quantityAvailable,
    required this.expiresAt,
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
  });

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    DateTime? asDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Product(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? 'Nevtelen termek',
      category: data['category'] as String? ?? 'Ismeretlen kategoria',
      originalPrice: data['originalPrice'] as int? ?? 0,
      discountedPrice: data['discountedPrice'] as int? ?? 0,
      quantity: data['quantity'] as int? ?? 0,
      quantityAvailable:
          data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0,
      expiresAt: asDate(data['expiresAt']),
      createdAt: asDate(data['createdAt']),
      location: data['location'] as GeoPoint?,
      interestCount: data['interestCount'] as int? ?? 0,
      status: data['status'] as String? ?? 'active',
      isDeleted: data['isDeleted'] as bool? ?? false,
      archivedAt: asDate(data['archivedAt']),
      deletedAt: asDate(data['deletedAt']),
      imageUrl: data['imageUrl'] as String?,
      imagePath: data['imagePath'] as String?,
      hasImage: data['hasImage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'quantityAvailable': quantityAvailable,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
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
    };
  }
}
