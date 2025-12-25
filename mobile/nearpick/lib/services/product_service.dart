import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Új termék hozzáadása az aktuálisan bejelentkezett kereskedőhöz
  Future<void> addProduct({
    required String name,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime expiresAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasználó.');
    }

    await _db.collection('products').add({
      'ownerId': user.uid,
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Az aktuális kereskedő saját termékei
  Stream<QuerySnapshot<Map<String, dynamic>>> myProductsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // üres stream, ha valamiért nincs user (nem kéne előforduljon)
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _db
        .collection('products')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('expiresAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeProductsStream() {
    final now = DateTime.now();

    return _db
        .collection('products')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .snapshots();
  }

  Future<void> markInterest({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nincs bejelentkezett felhasználó.');

    final docId = '${user.uid}_$productId';

    await _db.collection('interests').doc(docId).set({
      'userId': user.uid,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unmarkInterest({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nincs bejelentkezett felhasználó.');

    final docId = '${user.uid}_$productId';
    await _db.collection('interests').doc(docId).delete();
  }
}
