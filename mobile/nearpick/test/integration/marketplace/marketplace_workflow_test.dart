import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/product/product_workflow.dart';
import 'package:nearpick/core/reservation/reservation_workflow.dart';

import '../../test_helpers/in_memory_workflow_fakes.dart';

ReservationProductRecord reservationProductFromMap(
  String productId,
  Map<String, dynamic> data,
) {
  return ReservationProductRecord(
    id: productId,
    ownerId: data['ownerId'] as String? ?? '',
    name: data['name'] as String? ?? '',
    category: data['category'] as String? ?? '',
    originalPrice: data['originalPrice'] as int? ?? 0,
    discountedPrice: data['discountedPrice'] as int? ?? 0,
    quantity: data['quantity'] as int? ?? 0,
    quantityAvailable:
        data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0,
    status: data['status'] as String? ?? 'active',
    isDeleted: data['isDeleted'] == true,
    expiresAt: data['expiresAt'],
    imageUrl: data['imageUrl'] as String?,
  );
}

void main() {
  test(
    'Marketplace workflow covers product creation, interest, browse data and reservation',
    () async {
      final productRepository = InMemoryProductRepository();
      final interestGateway = InMemoryInterestGateway();

      final merchantSession = FakeProductSessionGateway()
        ..currentUserId = 'merchant-1';
      final productWorkflow = ProductWorkflow(
        sessionGateway: merchantSession,
        productRepository: productRepository,
        interestGateway: interestGateway,
        imageGateway: FakeProductImageGateway(),
      );

      final expiresAt = DateTime(2026, 3, 7, 18, 30);
      final productId = await productWorkflow.createProductWithOptionalImage(
        name: 'Sajtos pogacsa',
        category: 'Pekseg',
        originalPrice: 900,
        discountedPrice: 490,
        quantity: 2,
        expiresAt: expiresAt,
        imageBytes: Uint8List.fromList(const [9, 8, 7, 6]),
      );

      final createdProduct = productRepository.products[productId]!;
      expect(createdProduct['name'], 'Sajtos pogacsa');
      expect(createdProduct['category'], 'Pekseg');
      expect(createdProduct['hasImage'], true);
      expect(
        createdProduct['imagePath'],
        'products/merchant-1/product-1/main.jpg',
      );

      merchantSession.currentUserId = 'consumer-1';
      await productWorkflow.markInterest(productId: productId);

      expect(productRepository.readInterestCount(productId), 1);
      expect(interestGateway.records, contains('consumer-1::$productId'));

      final reservationSession = FakeReservationSessionGateway()
        ..currentUserId = 'consumer-1';
      final reservationProducts = InMemoryReservationProductGateway()
        ..products[productId] = reservationProductFromMap(
          productId,
          createdProduct,
        );
      final reservationStore = InMemoryReservationStore();
      final merchantStats = InMemoryMerchantStatsGateway();
      final reservationWorkflow = ReservationWorkflow(
        sessionGateway: reservationSession,
        productGateway: reservationProducts,
        reservationStore: reservationStore,
        merchantStatsGateway: merchantStats,
        pickupCodeGenerator: const FixedPickupCodeGenerator('ABC123'),
        now: () => DateTime(2026, 3, 6, 12),
      );

      final reservationId = await reservationWorkflow.reserveProduct(
        productId: productId,
      );

      expect(reservationId, 'reservation-1');
      expect(reservationProducts.products[productId]?.quantityAvailable, 1);
      expect(
        reservationStore.reservations[reservationId]?.buyerId,
        'consumer-1',
      );
      expect(
        reservationStore.reservations[reservationId]?.productSnapshot['name'],
        'Sajtos pogacsa',
      );
      expect(
        reservationStore
            .reservations[reservationId]
            ?.productSnapshot['category'],
        'Pekseg',
      );
    },
  );
}
