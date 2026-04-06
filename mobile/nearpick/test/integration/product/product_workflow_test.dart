import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/product/product_workflow.dart';

import '../../test_helpers/in_memory_workflow_fakes.dart';

void main() {
  test(
    'ProductWorkflow.createProductWithOptionalImage requires auth',
    () async {
      final session = FakeProductSessionGateway();
      final repository = InMemoryProductRepository();
      final interestGateway = InMemoryInterestGateway();
      final workflow = ProductWorkflow(
        sessionGateway: session,
        productRepository: repository,
        interestGateway: interestGateway,
        imageGateway: FakeProductImageGateway(),
      );

      await expectLater(
        workflow.createProductWithOptionalImage(
          name: 'Bagel',
          category: 'Pekseg',
          originalPrice: 1000,
          discountedPrice: 500,
          quantity: 2,
          expiresAt: DateTime(2026, 3, 7),
          pickupStartAt: DateTime(2026, 3, 7, 9),
          pickupEndAt: DateTime(2026, 3, 7, 12),
        ),
        throwsException,
      );
    },
  );

  test(
    'ProductWorkflow.markInterest is idempotent for the same user and product',
    () async {
      final session = FakeProductSessionGateway()..currentUserId = 'consumer-1';
      final repository = InMemoryProductRepository();
      final interestGateway = InMemoryInterestGateway();
      final workflow = ProductWorkflow(
        sessionGateway: session,
        productRepository: repository,
        interestGateway: interestGateway,
        imageGateway: FakeProductImageGateway(),
      );

      final productId = await workflow.createProductWithOptionalImage(
        name: 'Bagel',
        category: 'Pekseg',
        originalPrice: 1000,
        discountedPrice: 500,
        quantity: 2,
        expiresAt: DateTime(2026, 3, 7),
        pickupStartAt: DateTime(2026, 3, 7, 9),
        pickupEndAt: DateTime(2026, 3, 7, 12),
        imageBytes: Uint8List.fromList(const [1, 2, 3]),
      );

      await workflow.markInterest(productId: productId);
      await workflow.markInterest(productId: productId);

      expect(repository.readInterestCount(productId), 1);
      expect(interestGateway.records, {'consumer-1::$productId'});
    },
  );

  test(
    'ProductWorkflow.createProductWithOptionalImage stores browse and detail data',
    () async {
      final session = FakeProductSessionGateway()..currentUserId = 'merchant-1';
      final repository = InMemoryProductRepository();
      final interestGateway = InMemoryInterestGateway();
      final workflow = ProductWorkflow(
        sessionGateway: session,
        productRepository: repository,
        interestGateway: interestGateway,
        imageGateway: FakeProductImageGateway(),
      );

      final expiresAt = DateTime(2026, 3, 7, 18, 30);
      final pickupStartAt = DateTime(2026, 3, 7, 15);
      final pickupEndAt = DateTime(2026, 3, 7, 18);
      final productId = await workflow.createProductWithOptionalImage(
        name: 'Bagel Box',
        category: 'Pekseg',
        originalPrice: 1200,
        discountedPrice: 690,
        quantity: 3,
        expiresAt: expiresAt,
        pickupStartAt: pickupStartAt,
        pickupEndAt: pickupEndAt,
        merchantName: 'Penny',
        location: GeoPoint(46.253, 20.147),
        imageBytes: Uint8List.fromList(const [1, 2, 3, 4]),
      );

      expect(productId, 'product-1');
      expect(repository.products[productId], {
        'ownerId': 'merchant-1',
        'merchantName': 'Penny',
        'name': 'Bagel Box',
        'category': 'Pekseg',
        'originalPrice': 1200,
        'discountedPrice': 690,
        'quantity': 3,
        'quantityAvailable': 3,
        'expiresAt': expiresAt,
        'pickupStartAt': pickupStartAt,
        'pickupEndAt': pickupEndAt,
        'interestCount': 0,
        'status': 'active',
        'isDeleted': false,
        'archivedAt': null,
        'deletedAt': null,
        'hasImage': true,
        'hasReservations': false,
        'location': GeoPoint(46.253, 20.147),
        'imageUrl': 'https://example.test/merchant-1/product-1.jpg',
        'imagePath': 'products/merchant-1/product-1/main.jpg',
        'thumbnailPath': 'products/merchant-1/product-1/thumbnail.jpg',
      });
    },
  );
}
