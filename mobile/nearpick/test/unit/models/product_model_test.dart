import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/models/product.dart';

void main() {
  test('Product.fromMap uses fallbacks for missing fields', () {
    final product = Product.fromMap('p1', const {});

    expect(product.id, 'p1');
    expect(product.merchantName, '');
    expect(product.name, 'Nevtelen termek');
    expect(product.category, 'Ismeretlen kategoria');
    expect(product.quantityAvailable, 0);
    expect(product.hasReservations, false);
    expect(product.status, 'active');
    expect(product.pickupStartAt, isNull);
    expect(product.pickupEndAt, isNull);
  });

  test('Product.toMap serializes dates as Timestamp values', () {
    final createdAt = DateTime(2026, 3, 6, 10);
    final expiresAt = DateTime(2026, 3, 7, 12);
    final pickupStartAt = DateTime(2026, 3, 7, 9);
    final pickupEndAt = DateTime(2026, 3, 7, 14);
    final product = Product(
      id: 'p1',
      ownerId: 'merchant-1',
      merchantName: 'Penny',
      name: 'Bagel',
      category: 'Pekseg',
      originalPrice: 1000,
      discountedPrice: 500,
      quantity: 2,
      quantityAvailable: 2,
      expiresAt: expiresAt,
      pickupStartAt: pickupStartAt,
      pickupEndAt: pickupEndAt,
      createdAt: createdAt,
      location: const GeoPoint(47.5, 19.0),
      interestCount: 3,
      status: 'active',
      isDeleted: false,
      archivedAt: null,
      deletedAt: null,
      imageUrl: null,
      imagePath: null,
      thumbnailPath: null,
      hasImage: false,
      hasReservations: false,
      pricingRecommendation: null,
    );

    final map = product.toMap();
    expect(map['createdAt'], isA<Timestamp>());
    expect(map['expiresAt'], isA<Timestamp>());
    expect(map['pickupStartAt'], isA<Timestamp>());
    expect(map['pickupEndAt'], isA<Timestamp>());
    expect((map['createdAt'] as Timestamp).toDate(), createdAt);
    expect((map['expiresAt'] as Timestamp).toDate(), expiresAt);
    expect((map['pickupStartAt'] as Timestamp).toDate(), pickupStartAt);
    expect((map['pickupEndAt'] as Timestamp).toDate(), pickupEndAt);
    expect(map['merchantName'], 'Penny');
    expect(map['hasReservations'], false);
  });
}
