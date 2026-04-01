import '../../services/pickup_code_generator.dart';

class ReservationProductRecord {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final int originalPrice;
  final int discountedPrice;
  final int quantity;
  final int quantityAvailable;
  final String status;
  final bool isDeleted;
  final Object? expiresAt;
  final String? imageUrl;

  const ReservationProductRecord({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.quantityAvailable,
    required this.status,
    required this.isDeleted,
    required this.expiresAt,
    required this.imageUrl,
  });

  ReservationProductRecord copyWith({
    int? quantity,
    int? quantityAvailable,
    String? status,
  }) {
    return ReservationProductRecord(
      id: id,
      ownerId: ownerId,
      name: name,
      category: category,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      quantity: quantity ?? this.quantity,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      status: status ?? this.status,
      isDeleted: isDeleted,
      expiresAt: expiresAt,
      imageUrl: imageUrl,
    );
  }
}

class ReservationRecord {
  final String id;
  final String productId;
  final String merchantId;
  final String buyerId;
  final int qty;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? expiredAt;
  final String pickupCode;
  final String pickupToken;
  final String? cancelReasonCode;
  final String cancelReasonNote;
  final String? cancelledBy;
  final String refundStatus;
  final DateTime? refundRequestedAt;
  final DateTime? refundReviewedAt;
  final DateTime? refundCompletedAt;
  final Map<String, dynamic> productSnapshot;

  const ReservationRecord({
    required this.id,
    required this.productId,
    required this.merchantId,
    required this.buyerId,
    required this.qty,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.expiredAt,
    required this.pickupCode,
    required this.pickupToken,
    this.cancelReasonCode,
    this.cancelReasonNote = '',
    this.cancelledBy,
    this.refundStatus = 'not_requested',
    this.refundRequestedAt,
    this.refundReviewedAt,
    this.refundCompletedAt,
    required this.productSnapshot,
  });

  ReservationRecord copyWith({
    String? status,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? expiredAt,
    String? cancelReasonCode,
    String? cancelReasonNote,
    String? cancelledBy,
    String? refundStatus,
    DateTime? refundRequestedAt,
    DateTime? refundReviewedAt,
    DateTime? refundCompletedAt,
  }) {
    return ReservationRecord(
      id: id,
      productId: productId,
      merchantId: merchantId,
      buyerId: buyerId,
      qty: qty,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      expiredAt: expiredAt ?? this.expiredAt,
      pickupCode: pickupCode,
      pickupToken: pickupToken,
      cancelReasonCode: cancelReasonCode ?? this.cancelReasonCode,
      cancelReasonNote: cancelReasonNote ?? this.cancelReasonNote,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      refundStatus: refundStatus ?? this.refundStatus,
      refundRequestedAt: refundRequestedAt ?? this.refundRequestedAt,
      refundReviewedAt: refundReviewedAt ?? this.refundReviewedAt,
      refundCompletedAt: refundCompletedAt ?? this.refundCompletedAt,
      productSnapshot: productSnapshot,
    );
  }
}

abstract class ReservationSessionGateway {
  String? get currentUserId;
}

abstract class ReservationProductGateway {
  ReservationProductRecord? getProduct(String productId);

  Future<void> saveProduct(ReservationProductRecord product);
}

abstract class ReservationStoreGateway {
  String nextReservationId();

  Future<void> saveReservation(ReservationRecord reservation);

  ReservationRecord? getReservation(String reservationId);

  Future<void> saveUpdatedReservation(ReservationRecord reservation);
}

abstract class MerchantStatsGateway {
  Future<void> incrementReserved(String merchantId);

  Future<void> incrementSoldOut(String merchantId);

  Future<void> incrementCompleted(String merchantId);
}

class ReservationWorkflow {
  final ReservationSessionGateway sessionGateway;
  final ReservationProductGateway productGateway;
  final ReservationStoreGateway reservationStore;
  final MerchantStatsGateway merchantStatsGateway;
  final PickupCodeGenerator pickupCodeGenerator;
  final DateTime Function() now;

  const ReservationWorkflow({
    required this.sessionGateway,
    required this.productGateway,
    required this.reservationStore,
    required this.merchantStatsGateway,
    required this.pickupCodeGenerator,
    required this.now,
  });

  Future<String> reserveProduct({required String productId}) async {
    final userId = sessionGateway.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final product = productGateway.getProduct(productId);
    if (product == null) {
      throw Exception('A termek nem talalhato.');
    }
    if (product.status != 'active' || product.isDeleted) {
      throw Exception('A termek mar nem elerheto.');
    }
    if (product.quantityAvailable <= 0) {
      throw Exception('Elfogyott');
    }

    final newQty = product.quantityAvailable - 1;
    final reservationId = reservationStore.nextReservationId();
    final createdAt = now();
    final expiresAt = createdAt.add(const Duration(minutes: 30));
    final pickupCode = pickupCodeGenerator.generate(6);

    await productGateway.saveProduct(
      product.copyWith(
        quantity: newQty,
        quantityAvailable: newQty,
        status: newQty == 0 ? 'sold_out' : product.status,
      ),
    );

    await reservationStore.saveReservation(
      ReservationRecord(
        id: reservationId,
        productId: productId,
        merchantId: product.ownerId,
        buyerId: userId,
        qty: 1,
        status: 'reserved',
        createdAt: createdAt,
        expiresAt: expiresAt,
        completedAt: null,
        cancelledAt: null,
        expiredAt: null,
        pickupCode: pickupCode,
        pickupToken: 'NEARPICK:$reservationId:$pickupCode',
        cancelReasonCode: null,
        cancelReasonNote: '',
        cancelledBy: null,
        refundStatus: 'not_requested',
        refundRequestedAt: null,
        refundReviewedAt: null,
        refundCompletedAt: null,
        productSnapshot: {
          'name': product.name,
          'discountedPrice': product.discountedPrice,
          'originalPrice': product.originalPrice,
          'imageUrl': product.imageUrl,
          'expiresAt': product.expiresAt,
          'category': product.category,
        },
      ),
    );

    if (product.ownerId.isNotEmpty) {
      await merchantStatsGateway.incrementReserved(product.ownerId);
      if (newQty == 0) {
        await merchantStatsGateway.incrementSoldOut(product.ownerId);
      }
    }

    return reservationId;
  }

  Future<void> completeReservation({required String reservationId}) async {
    await completeReservationByPickup(
      reservationId: reservationId,
      pickupInput: null,
    );
  }

  Future<void> completeReservationByPickup({
    required String reservationId,
    required String? pickupInput,
  }) async {
    final userId = sessionGateway.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final reservation = reservationStore.getReservation(reservationId);
    if (reservation == null) {
      throw Exception('A foglalas nem talalhato.');
    }
    if (reservation.merchantId.isEmpty || reservation.merchantId != userId) {
      throw Exception('Nincs jogosultsag a foglalashoz.');
    }
    if (reservation.status != 'reserved') {
      return;
    }
    if (reservation.expiresAt.isBefore(now()) ||
        reservation.expiresAt.isAtSameMomentAs(now())) {
      throw Exception('A foglalas mar lejart.');
    }
    final normalizedInput = (pickupInput ?? '').trim();
    if (normalizedInput.isNotEmpty &&
        normalizedInput != reservation.pickupCode &&
        normalizedInput != reservation.pickupToken) {
      throw Exception('Ervenytelen atveteli kod.');
    }

    await reservationStore.saveUpdatedReservation(
      reservation.copyWith(status: 'completed', completedAt: now()),
    );
    await merchantStatsGateway.incrementCompleted(userId);
  }

  Future<void> cancelReservation({
    required String reservationId,
    String reasonCode = 'changed_mind',
    String reasonNote = '',
    bool refundRequested = false,
  }) async {
    final userId = sessionGateway.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final reservation = reservationStore.getReservation(reservationId);
    if (reservation == null) {
      throw Exception('A foglalas nem talalhato.');
    }
    if (reservation.buyerId.isEmpty || reservation.buyerId != userId) {
      throw Exception('Nincs jogosultsag a foglalashoz.');
    }
    if (reservation.status != 'reserved') {
      return;
    }

    final product = productGateway.getProduct(reservation.productId);
    if (product != null && !product.isDeleted) {
      final newQty = product.quantityAvailable + reservation.qty;
      await productGateway.saveProduct(
        product.copyWith(
          quantity: newQty,
          quantityAvailable: newQty,
          status: 'active',
        ),
      );
    }

    await reservationStore.saveUpdatedReservation(
      reservation.copyWith(
        status: 'cancelled',
        cancelledAt: now(),
        cancelReasonCode: reasonCode,
        cancelReasonNote: reasonNote.trim(),
        cancelledBy: 'buyer',
        refundStatus: refundRequested ? 'pending' : 'not_requested',
        refundRequestedAt: refundRequested ? now() : null,
        refundReviewedAt: null,
        refundCompletedAt: null,
      ),
    );
  }
}
