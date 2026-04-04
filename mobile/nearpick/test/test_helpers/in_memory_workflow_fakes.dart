import 'dart:typed_data';

import 'package:nearpick/core/auth/auth_workflow.dart';
import 'package:nearpick/core/product/product_workflow.dart';
import 'package:nearpick/core/reservation/reservation_workflow.dart';
import 'package:nearpick/services/pickup_code_generator.dart';

class FakeAuthGateway implements AuthGateway {
  final Map<String, String> _passwordByEmail = {};
  final List<String> passwordResetEmails = [];
  int _idCounter = 0;

  @override
  String? currentUserId;

  @override
  Future<AuthIdentity> createUser({
    required String email,
    required String password,
  }) async {
    _idCounter += 1;
    final uid = 'user-$_idCounter';
    _passwordByEmail[email] = password;
    currentUserId = uid;
    return AuthIdentity(uid: uid, email: email);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final stored = _passwordByEmail[email];
    if (stored == null || stored != password) {
      throw StateError('invalid-credentials');
    }
    currentUserId = 'signed-in-$email';
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!_passwordByEmail.containsKey(email)) {
      throw StateError('user-not-found');
    }
    passwordResetEmails.add(email);
  }

  @override
  Future<void> signOut() async {
    currentUserId = null;
  }
}

class FakeUserProfileGateway implements UserProfileGateway {
  final Map<String, Map<String, String>> profiles = {};

  @override
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required String role,
    required String companyName,
  }) async {
    profiles[uid] = {
      'email': email,
      'displayName': displayName,
      'role': role,
      'companyName': companyName,
    };
  }
}

class FakeProductSessionGateway implements ProductSessionGateway {
  @override
  String? currentUserId;
}

class InMemoryProductRepository implements ProductRepositoryGateway {
  int _nextId = 0;
  final Map<String, Map<String, dynamic>> products = {};

  @override
  String nextProductId() {
    _nextId += 1;
    return 'product-$_nextId';
  }

  @override
  Future<void> saveProduct({
    required String productId,
    required Map<String, dynamic> data,
  }) async {
    products[productId] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> incrementInterestCount({
    required String productId,
    required int delta,
  }) async {
    final product = products[productId];
    if (product == null) {
      throw StateError('missing-product');
    }
    product['interestCount'] = (product['interestCount'] as int? ?? 0) + delta;
  }

  @override
  int readInterestCount(String productId) {
    return products[productId]?['interestCount'] as int? ?? 0;
  }
}

class InMemoryInterestGateway implements ProductInterestGateway {
  final Set<String> records = {};

  @override
  Future<bool> exists({
    required String userId,
    required String productId,
  }) async {
    return records.contains('$userId::$productId');
  }

  @override
  Future<void> save({required String userId, required String productId}) async {
    records.add('$userId::$productId');
  }
}

class FakeProductImageGateway implements ProductImageGateway {
  @override
  Future<ProductImageUploadResult> upload({
    required String ownerId,
    required String productId,
    required Uint8List imageBytes,
  }) async {
    return ProductImageUploadResult(
      downloadUrl: 'https://example.test/$ownerId/$productId.jpg',
      imagePath: 'products/$ownerId/$productId/main.jpg',
    );
  }
}

class FakeReservationSessionGateway implements ReservationSessionGateway {
  @override
  String? currentUserId;
}

class InMemoryReservationProductGateway implements ReservationProductGateway {
  final Map<String, ReservationProductRecord> products = {};

  @override
  ReservationProductRecord? getProduct(String productId) {
    return products[productId];
  }

  @override
  Future<void> saveProduct(ReservationProductRecord product) async {
    products[product.id] = product;
  }
}

class InMemoryReservationStore implements ReservationStoreGateway {
  int _nextId = 0;
  final Map<String, ReservationRecord> reservations = {};

  @override
  String nextReservationId() {
    _nextId += 1;
    return 'reservation-$_nextId';
  }

  @override
  ReservationRecord? getReservation(String reservationId) {
    return reservations[reservationId];
  }

  @override
  Future<void> saveUpdatedReservation(ReservationRecord reservation) async {
    reservations[reservation.id] = reservation;
  }

  @override
  Future<void> saveReservation(ReservationRecord reservation) async {
    reservations[reservation.id] = reservation;
  }
}

class InMemoryMerchantStatsGateway implements MerchantStatsGateway {
  final Map<String, Map<String, int>> stats = {};

  Map<String, int> _entry(String merchantId) {
    return stats.putIfAbsent(
      merchantId,
      () => {'reservedCount': 0, 'soldOutCount': 0, 'completedCount': 0},
    );
  }

  @override
  Future<void> incrementCompleted(String merchantId) async {
    _entry(merchantId)['completedCount'] =
        (_entry(merchantId)['completedCount'] ?? 0) + 1;
  }

  @override
  Future<void> incrementReserved(String merchantId) async {
    _entry(merchantId)['reservedCount'] =
        (_entry(merchantId)['reservedCount'] ?? 0) + 1;
  }

  @override
  Future<void> incrementSoldOut(String merchantId) async {
    _entry(merchantId)['soldOutCount'] =
        (_entry(merchantId)['soldOutCount'] ?? 0) + 1;
  }
}

class FixedPickupCodeGenerator implements PickupCodeGenerator {
  final String code;

  const FixedPickupCodeGenerator(this.code);

  @override
  String generate(int length) {
    return code.substring(0, length);
  }
}
