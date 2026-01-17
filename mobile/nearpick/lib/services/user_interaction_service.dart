import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class UserInteractionService {
  final FirebaseFirestore _firestore;

  UserInteractionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logProductView({
    required String uid,
    required String productId,
    required String ownerId,
    required String category,
  }) async {
    if (uid.isEmpty || productId.isEmpty || ownerId.isEmpty || category.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('userInteractions').add({
        'uid': uid,
        'userId': uid,
        'ownerId': ownerId,
        'type': 'view',
        'productId': productId,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore audit failures to keep implicit prefs working.
    }

    await _firestore.collection('userImplicitPrefs').doc(uid).set(
      {
        'categoryViews': {category: FieldValue.increment(1)},
        'categoryLastViewedAt': {category: FieldValue.serverTimestamp()},
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> logProductInterest({
    required String uid,
    required String productId,
    required String ownerId,
    required String category,
  }) async {
    if (uid.isEmpty || productId.isEmpty || ownerId.isEmpty || category.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('userInteractions').add({
        'uid': uid,
        'userId': uid,
        'ownerId': ownerId,
        'type': 'interest',
        'productId': productId,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore audit failures to keep implicit prefs working.
    }
  }

  Future<void> compactImplicitPrefsIfNeeded({required String uid}) async {
    if (uid.isEmpty) return;

    try {
      final docRef = _firestore.collection('userImplicitPrefs').doc(uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final now = DateTime.now();
      final lastCompactedAt = data['lastCompactedAt'] is Timestamp
          ? (data['lastCompactedAt'] as Timestamp).toDate()
          : null;
      if (lastCompactedAt != null &&
          now.difference(lastCompactedAt).inHours < 24) {
        return;
      }

      const halfLifeDays = 7.0;
      final lambda = math.ln2 / halfLifeDays;

      final rawViews = data['categoryViews'];
      final rawLastViewed = data['categoryLastViewedAt'];
      if (rawViews is! Map && rawLastViewed is! Map) {
        await docRef.set(
          {
            'lastCompactedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }

      final Map<String, Object?> newCategoryViews = {};
      final Map<String, Object?> newCategoryLastViewedAt = {};

      if (rawLastViewed is Map) {
        rawLastViewed.forEach((key, value) {
          if (key is String) {
            newCategoryLastViewedAt[key] = value;
          }
        });
      }

      if (rawViews is Map) {
        rawViews.forEach((key, value) {
          if (key is! String) return;

          if (value is! num) {
            newCategoryViews[key] = value;
            return;
          }

          final lastViewedValue = newCategoryLastViewedAt[key];
          final lastViewedAt = lastViewedValue is Timestamp
              ? lastViewedValue.toDate()
              : null;
          final ageDays = lastViewedAt == null
              ? 999.0
              : now.difference(lastViewedAt).inHours / 24.0;
          final decayFactor = math.exp(-lambda * ageDays);
          final effectiveCount = value.toDouble() * decayFactor;
          final newCount = effectiveCount.round();

          if (newCount <= 0 && ageDays > 30.0) {
            newCategoryViews.remove(key);
            newCategoryLastViewedAt.remove(key);
            return;
          }

          newCategoryViews[key] = newCount;
        });
      }

      await docRef.set(
        {
          'categoryViews': newCategoryViews,
          'categoryLastViewedAt': newCategoryLastViewedAt,
          'lastCompactedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Best-effort: ignore compaction failures.
    }
  }
}

// TODO(firestore-rules):
// match /userImplicitPrefs/{uid} {
//   allow read, write: if request.auth != null && request.auth.uid == uid;
// }
// match /userInteractions/{docId} {
//   allow create: if request.auth != null
//     && request.resource.data.uid == request.auth.uid;
//   allow read: if false;
// }
