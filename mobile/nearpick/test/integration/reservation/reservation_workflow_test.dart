import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/reservation/reservation_workflow.dart';

import '../../test_helpers/in_memory_workflow_fakes.dart';

void main() {
  test(
    'ReservationWorkflow.reserveProduct updates quantity and merchant stats',
    () async {
      final session = FakeReservationSessionGateway()
        ..currentUserId = 'buyer-1';
      final productGateway = InMemoryReservationProductGateway()
        ..products['product-1'] = const ReservationProductRecord(
          id: 'product-1',
          ownerId: 'merchant-1',
          name: 'Bagel',
          category: 'Pekseg',
          originalPrice: 1000,
          discountedPrice: 500,
          quantity: 1,
          quantityAvailable: 1,
          status: 'active',
          isDeleted: false,
          expiresAt: null,
          imageUrl: null,
        );
      final reservationStore = InMemoryReservationStore();
      final merchantStats = InMemoryMerchantStatsGateway();
      final workflow = ReservationWorkflow(
        sessionGateway: session,
        productGateway: productGateway,
        reservationStore: reservationStore,
        merchantStatsGateway: merchantStats,
        pickupCodeGenerator: const FixedPickupCodeGenerator('ABC123'),
        now: () => DateTime(2026, 3, 6, 12),
      );

      final reservationId = await workflow.reserveProduct(
        productId: 'product-1',
      );

      expect(reservationId, 'reservation-1');
      expect(productGateway.products['product-1']?.quantityAvailable, 0);
      expect(productGateway.products['product-1']?.status, 'sold_out');
      expect(
        reservationStore.reservations[reservationId]?.pickupCode,
        'ABC123',
      );
      expect(merchantStats.stats['merchant-1']?['reservedCount'], 1);
      expect(merchantStats.stats['merchant-1']?['soldOutCount'], 1);
    },
  );

  test(
    'ReservationWorkflow.completeReservation rejects foreign merchant user',
    () async {
      final session = FakeReservationSessionGateway()
        ..currentUserId = 'merchant-2';
      final productGateway = InMemoryReservationProductGateway();
      final reservationStore = InMemoryReservationStore()
        ..reservations['reservation-1'] = ReservationRecord(
          id: 'reservation-1',
          productId: 'product-1',
          merchantId: 'merchant-1',
          buyerId: 'buyer-1',
          qty: 1,
          status: 'reserved',
          createdAt: DateTime(2026, 3, 6, 12),
          expiresAt: DateTime(2026, 3, 6, 12, 30),
          pickupCode: 'ABC123',
          productSnapshot: const {'name': 'Bagel'},
        );
      final merchantStats = InMemoryMerchantStatsGateway();
      final workflow = ReservationWorkflow(
        sessionGateway: session,
        productGateway: productGateway,
        reservationStore: reservationStore,
        merchantStatsGateway: merchantStats,
        pickupCodeGenerator: const FixedPickupCodeGenerator('ABC123'),
        now: () => DateTime(2026, 3, 6, 12),
      );

      await expectLater(
        workflow.completeReservation(reservationId: 'reservation-1'),
        throwsException,
      );
      expect(
        reservationStore.reservations['reservation-1']?.status,
        'reserved',
      );
    },
  );

  test(
    'ReservationWorkflow.completeReservation completes reserved reservations for the owning merchant',
    () async {
      final session = FakeReservationSessionGateway()
        ..currentUserId = 'merchant-1';
      final productGateway = InMemoryReservationProductGateway();
      final reservationStore = InMemoryReservationStore()
        ..reservations['reservation-1'] = ReservationRecord(
          id: 'reservation-1',
          productId: 'product-1',
          merchantId: 'merchant-1',
          buyerId: 'buyer-1',
          qty: 1,
          status: 'reserved',
          createdAt: DateTime(2026, 3, 6, 12),
          expiresAt: DateTime(2026, 3, 6, 12, 30),
          pickupCode: 'ABC123',
          productSnapshot: const {'name': 'Bagel'},
        );
      final merchantStats = InMemoryMerchantStatsGateway();
      final workflow = ReservationWorkflow(
        sessionGateway: session,
        productGateway: productGateway,
        reservationStore: reservationStore,
        merchantStatsGateway: merchantStats,
        pickupCodeGenerator: const FixedPickupCodeGenerator('ABC123'),
        now: () => DateTime(2026, 3, 6, 12),
      );

      await workflow.completeReservation(reservationId: 'reservation-1');

      expect(
        reservationStore.reservations['reservation-1']?.status,
        'completed',
      );
      expect(merchantStats.stats['merchant-1']?['completedCount'], 1);
    },
  );
}
