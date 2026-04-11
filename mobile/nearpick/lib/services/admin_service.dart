import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_user_profile.dart';
import '../models/merchant_stats_summary.dart';
import '../models/product.dart';
import '../models/reservation.dart';

class AdminService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  AdminService({FirebaseFirestore? db, FirebaseFunctions? functions})
    : _db = db ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  Stream<List<AppUserProfile>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(AppUserProfile.fromDoc).toList();
        });
  }

  Stream<List<Product>> watchProducts() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(Product.fromDoc).toList();
        });
  }

  Stream<List<Reservation>> watchReservations() {
    return _db
        .collection('reservations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(Reservation.fromDoc).toList();
        });
  }

  Stream<List<MerchantStatsSummary>> watchMerchantStats() {
    return _db.collection('merchantStats').snapshots().map((snapshot) {
      return snapshot.docs.map(MerchantStatsSummary.fromDoc).toList();
    });
  }

  Future<void> updateUserAccountStatus({
    required String userId,
    required String accountStatus,
  }) async {
    try {
      final callable = _functions.httpsCallable('setUserAccountStatus');
      await callable.call(<String, dynamic>{
        'userId': userId,
        'accountStatus': accountStatus,
      });
    } on FirebaseFunctionsException catch (error) {
      throw Exception(
        error.message ?? 'A felhasznalo allapota nem modosithato.',
      );
    }
  }

  Future<void> hideProduct({required String productId}) async {
    try {
      final callable = _functions.httpsCallable('hideProductForAdmin');
      await callable.call(<String, dynamic>{'productId': productId});
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? 'A termek nem rejtheto el.');
    }
  }

  Future<void> restoreProduct({required String productId}) async {
    try {
      final callable = _functions.httpsCallable('restoreProductForAdmin');
      await callable.call(<String, dynamic>{'productId': productId});
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? 'A termek nem allithato vissza.');
    }
  }

  Future<void> deleteProduct({required String productId}) async {
    try {
      final callable = _functions.httpsCallable('deleteProductForAdmin');
      await callable.call(<String, dynamic>{'productId': productId});
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? 'A termek torlese nem sikerult.');
    }
  }
}
