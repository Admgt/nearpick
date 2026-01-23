import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Új termék hozzáadása az aktuálisan bejelentkezett kereskedőhöz
  Future<void> addProduct({
    required String name,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime expiresAt,
    GeoPoint? location,
  }) async {
    await createProductWithOptionalImage(
      name: name,
      category: category,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      quantity: quantity,
      expiresAt: expiresAt,
      location: location,
      imageBytes: null,
    );
  }

  Future<void> createProductWithOptionalImage({
    required String name,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime expiresAt,
    GeoPoint? location,
    Uint8List? imageBytes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznÇ­lÇü.');
    }

    final docRef = _db.collection('products').doc();

    final data = <String, dynamic>{
      'ownerId': user.uid,
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'quantityAvailable': quantity,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
      'interestCount': 0,
      'status': 'active',
      'isDeleted': false,
      'archivedAt': null,
      'deletedAt': null,
    };
    if (location != null) {
      data['location'] = location;
    }

    if (imageBytes != null) {
      final imageRef = _storage
          .ref()
          .child('products')
          .child(user.uid)
          .child(docRef.id)
          .child('main.jpg');
      await imageRef.putData(imageBytes);
      final downloadUrl = await imageRef.getDownloadURL();
      data['imageUrl'] = downloadUrl;
      data['imagePath'] = imageRef.fullPath;
      data['hasImage'] = true;
    } else {
      data['hasImage'] = false;
    }

    await docRef.set(data);
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
        .where('status', isEqualTo: 'active')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listActiveProducts() {
    return activeProductsStream();
  }

  Future<void> archiveProduct({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznÇ­lÇü.');
    }

    // TODO: Add scheduled cleanup for archived product images in Storage.
    await _db.collection('products').doc(productId).update({
      'status': 'archived',
      'isDeleted': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markInterest({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nincs bejelentkezett felhasználó.');

    final interestDocId = '${user.uid}_$productId';
    final interestRef = _db.collection('interests').doc(interestDocId);
    final productRef = _db.collection('products').doc(productId);

    await _db.runTransaction((tx) async {
      final interestSnap = await tx.get(interestRef);

      if (interestSnap.exists) return;

      tx.set(interestRef, {
        'userId': user.uid,
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(productRef, {'interestCount': FieldValue.increment(1)});
    });
  }

  Future<void> unmarkInterest({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nincs bejelentkezett felhasználó.');

    final interestDocId = '${user.uid}_$productId';
    final interestRef = _db.collection('interests').doc(interestDocId);
    final productRef = _db.collection('products').doc(productId);

    await _db.runTransaction((tx) async {
      final interestSnap = await tx.get(interestRef);

      if (!interestSnap.exists) return;

      tx.delete(interestRef);

      final productSnap = await tx.get(productRef);
      final current = (productSnap.data()?['interestCount'] as int?) ?? 0;
      if (current > 0) {
        tx.update(productRef, {'interestCount': FieldValue.increment(-1)});
      }
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myInterestsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _db
        .collection('interests')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }
}
