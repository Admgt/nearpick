import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/error/app_exception.dart';
import '../features/merchant/dynamic_pricing.dart';

class DynamicPricingService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DynamicPricingService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<DynamicPricingRecommendation> buildRecommendation({
    required String category,
    required int originalPrice,
    required int quantity,
    required DateTime expiresAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Bejelentkezes szukseges.',
      );
    }

    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 7));

    final futures = await Future.wait([
      _db
          .collection('userInteractions')
          .where('ownerId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get(),
      _db.collection('products').where('ownerId', isEqualTo: user.uid).get(),
    ]);
    final interactionsQuery = futures.first;
    final productsQuery = futures.last;

    final interactions = interactionsQuery.docs
        .map((doc) => doc.data())
        .toList();
    final products = productsQuery.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'expiresAt': (data['expiresAt'] as Timestamp?)?.toDate(),
      };
    }).toList();

    final marketSnapshot = buildMerchantMarketSnapshot(
      category: category,
      interactions: interactions,
      products: products,
      now: now,
    );

    return buildDynamicPricingRecommendation(
      originalPrice: originalPrice,
      quantity: quantity,
      expiresAt: expiresAt,
      marketSnapshot: marketSnapshot,
      now: now,
    );
  }
}
