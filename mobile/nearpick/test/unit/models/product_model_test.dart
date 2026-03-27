import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/models/product.dart';

void main() {
  test('Product.fromMap uses fallbacks for missing fields', () {
    final product = Product.fromMap('p1', const {});

    expect(product.id, 'p1');
    expect(product.name, 'Nevtelen termek');
    expect(product.category, 'Ismeretlen kategoria');
    expect(product.quantityAvailable, 0);
    expect(product.status, 'active');
  });

  test('Product.toMap serializes dates as Timestamp values', () {
    final createdAt = DateTime(2026, 3, 6, 10);
    final expiresAt = DateTime(2026, 3, 7, 12);
    final product = Product(
      id: 'p1',
      ownerId: 'merchant-1',
      name: 'Bagel',
      category: 'Pekseg',
      originalPrice: 1000,
      discountedPrice: 500,
      quantity: 2,
      quantityAvailable: 2,
      expiresAt: expiresAt,
      createdAt: createdAt,
      location: const GeoPoint(47.5, 19.0),
      interestCount: 3,
      status: 'active',
      isDeleted: false,
      archivedAt: null,
      deletedAt: null,
      imageUrl: null,
      imagePath: null,
      hasImage: false,
      pricingRecommendation: null,
    );

    final map = product.toMap();
    expect(map['createdAt'], isA<Timestamp>());
    expect(map['expiresAt'], isA<Timestamp>());
    expect((map['createdAt'] as Timestamp).toDate(), createdAt);
    expect((map['expiresAt'] as Timestamp).toDate(), expiresAt);
  });
}
