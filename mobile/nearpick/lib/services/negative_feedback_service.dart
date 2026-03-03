import 'package:cloud_firestore/cloud_firestore.dart';

class NegativeFeedbackService {
  final FirebaseFirestore _firestore;

  NegativeFeedbackService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> dismissCategoryForProduct({
    required String userId,
    required String productId,
    required String category,
    String? ownerId,
  }) async {
    if (userId.isEmpty || productId.isEmpty || category.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('userInteractions').add({
        'uid': userId,
        'userId': userId,
        'productId': productId,
        'category': category,
        'type': 'dismiss',
        'createdAt': FieldValue.serverTimestamp(),
        if (ownerId != null && ownerId.isNotEmpty) 'ownerId': ownerId,
      });
    } catch (_) {
      // Best-effort audit logging.
    }

    await _firestore.collection('userNegativePrefs').doc(userId).set({
      'categoryDismissals': {category: FieldValue.increment(1)},
      'categoryLastDismissedAt': {category: FieldValue.serverTimestamp()},
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
