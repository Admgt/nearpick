import 'package:cloud_firestore/cloud_firestore.dart';

class UserInteractionService {
  final FirebaseFirestore _firestore;

  UserInteractionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logProductView({
    required String uid,
    required String productId,
    required String category,
  }) async {
    if (uid.isEmpty || productId.isEmpty || category.isEmpty) return;

    try {
      await _firestore.collection('userInteractions').add({
        'uid': uid,
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
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
