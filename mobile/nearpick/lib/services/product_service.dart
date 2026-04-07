import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../features/merchant/dynamic_pricing.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Reference _mainImageRef({
    required String ownerId,
    required String productId,
  }) {
    return _storage
        .ref()
        .child('products')
        .child(ownerId)
        .child(productId)
        .child('main.jpg');
  }

  Reference _thumbnailImageRef({
    required String ownerId,
    required String productId,
  }) {
    return _storage
        .ref()
        .child('products')
        .child(ownerId)
        .child(productId)
        .child('thumbnail.jpg');
  }

  Future<Map<String, dynamic>> _loadMerchantProfile(User user) async {
    final profile = await _db.collection('users').doc(user.uid).get();
    return profile.data() ?? const <String, dynamic>{};
  }

  String _resolveMerchantName(User user, Map<String, dynamic> data) {
    final companyName = (data['companyName'] as String?)?.trim() ?? '';
    if (companyName.isNotEmpty) {
      return companyName;
    }

    final displayName = (data['displayName'] as String?)?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    return (user.email ?? user.uid).trim();
  }

  GeoPoint? _resolveMerchantLocation(Map<String, dynamic> data) {
    return data['companyLocation'] as GeoPoint?;
  }

  /// Új termék hozzáadása az aktuálisan bejelentkezett kereskedőhöz
  Future<void> addProduct({
    required String name,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime expiresAt,
    required DateTime pickupStartAt,
    required DateTime pickupEndAt,
    GeoPoint? location,
  }) async {
    await createProductWithOptionalImage(
      name: name,
      category: category,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      quantity: quantity,
      expiresAt: expiresAt,
      pickupStartAt: pickupStartAt,
      pickupEndAt: pickupEndAt,
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
    required DateTime pickupStartAt,
    required DateTime pickupEndAt,
    GeoPoint? location,
    Uint8List? imageBytes,
    DynamicPricingRecommendation? pricingRecommendation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznÇ­lÇü.');
    }

    final docRef = _db.collection('products').doc();
    final profileData = await _loadMerchantProfile(user);
    final merchantName = _resolveMerchantName(user, profileData);
    final resolvedLocation = location ?? _resolveMerchantLocation(profileData);
    if (resolvedLocation == null) {
      throw Exception(
        'A ceg helye nincs beallitva. Add meg a Profil ful alatt a ceg helyet.',
      );
    }

    final data = <String, dynamic>{
      'ownerId': user.uid,
      'merchantName': merchantName,
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'quantityAvailable': quantity,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'pickupStartAt': Timestamp.fromDate(pickupStartAt),
      'pickupEndAt': Timestamp.fromDate(pickupEndAt),
      'createdAt': FieldValue.serverTimestamp(),
      'interestCount': 0,
      'status': 'active',
      'isDeleted': false,
      'archivedAt': null,
      'deletedAt': null,
      'hasReservations': false,
    };
    data['location'] = resolvedLocation;
    if (pricingRecommendation != null) {
      data['pricingRecommendation'] = {
        ...pricingRecommendation.toProductSnapshot(),
        'generatedAt': FieldValue.serverTimestamp(),
      };
    }

    if (imageBytes != null) {
      final imageRef = _mainImageRef(ownerId: user.uid, productId: docRef.id);
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

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime expiresAt,
    required DateTime pickupStartAt,
    required DateTime pickupEndAt,
    GeoPoint? location,
    Uint8List? imageBytes,
    bool removeImage = false,
    DynamicPricingRecommendation? pricingRecommendation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final productRef = _db.collection('products').doc(productId);
    final productSnap = await productRef.get();
    if (!productSnap.exists) {
      throw Exception('A termek nem talalhato.');
    }

    final existingProduct = Product.fromDoc(productSnap);
    if (existingProduct.ownerId != user.uid) {
      throw Exception('Nincs jogosultsag.');
    }
    if (existingProduct.hasReservations) {
      throw Exception(
        'A termeket mar lefoglaltak, ezert tovabb nem modosithato.',
      );
    }

    final data = <String, dynamic>{
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'quantityAvailable': quantity,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'pickupStartAt': Timestamp.fromDate(pickupStartAt),
      'pickupEndAt': Timestamp.fromDate(pickupEndAt),
      'hasReservations': false,
    };

    if (location != null) {
      data['location'] = location;
    } else {
      data['location'] = FieldValue.delete();
    }

    if (pricingRecommendation != null) {
      data['pricingRecommendation'] = {
        ...pricingRecommendation.toProductSnapshot(),
        'generatedAt': FieldValue.serverTimestamp(),
      };
    } else {
      data['pricingRecommendation'] = FieldValue.delete();
    }

    if (imageBytes != null) {
      final imageRef = _mainImageRef(ownerId: user.uid, productId: productId);
      await imageRef.putData(imageBytes);
      final downloadUrl = await imageRef.getDownloadURL();
      data['imageUrl'] = downloadUrl;
      data['imagePath'] = imageRef.fullPath;
      data['hasImage'] = true;
    } else if (removeImage) {
      final imagePath = existingProduct.imagePath;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          await _storage.ref().child(imagePath).delete();
        } catch (_) {}
      }
      final thumbnailPath = existingProduct.thumbnailPath;
      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        try {
          await _storage.ref().child(thumbnailPath).delete();
        } catch (_) {}
      } else {
        try {
          await _thumbnailImageRef(
            ownerId: user.uid,
            productId: productId,
          ).delete();
        } catch (_) {}
      }
      data['hasImage'] = false;
      data['imageUrl'] = FieldValue.delete();
      data['imagePath'] = FieldValue.delete();
      data['thumbnailPath'] = FieldValue.delete();
    }

    await productRef.update(data);
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

    try {
      final callable = _functions.httpsCallable('archiveProduct');
      await callable.call(<String, dynamic>{'productId': productId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'A termek archivalsa nem sikerult.');
    }
  }

  Future<int> applyRecommendedPrice({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    try {
      final callable = _functions.httpsCallable('repriceProduct');
      final response = await callable.call(<String, dynamic>{
        'productId': productId,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      final discountedPrice = data['discountedPrice'];
      if (discountedPrice is! int || discountedPrice <= 0) {
        throw Exception('A szerver nem adott vissza ervenyes uj arat.');
      }
      return discountedPrice;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'A termek ujraarazasa nem sikerult.');
    }
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

  Future<void> unmarkInterestForCurrentUser({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nincs bejelentkezett felhasználó.');

    final query = await _db
        .collection('interests')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    await unmarkInterestByRef(
      interestRef: query.docs.first.reference,
      productId: productId,
    );
  }

  Future<void> unmarkInterestByRef({
    required DocumentReference<Map<String, dynamic>> interestRef,
    required String productId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nincs bejelentkezett felhasznÃ¡lÃ³.');

    final productRef = _db.collection('products').doc(productId);

    final interestSnap = await interestRef.get();
    if (!interestSnap.exists) return;

    final ownerId = interestSnap.data()?['userId'] as String?;
    if (ownerId != null && ownerId != user.uid) {
      throw Exception('Nincs jogosultsÃ¡g.');
    }

    await interestRef.delete();

    // Best-effort counter update; do not block favorite removal on permission issues.
    try {
      await productRef.update({'interestCount': FieldValue.increment(-1)});
    } catch (_) {}
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
