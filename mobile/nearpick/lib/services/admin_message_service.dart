import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/admin_message.dart';

class AdminMessageService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  AdminMessageService({FirebaseFirestore? db, FirebaseFunctions? functions})
    : _db = db ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  Stream<List<AdminMessage>> watchMessagesForUser(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('adminMessages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(AdminMessage.fromDoc).toList();
        });
  }

  Future<void> sendMessageToMerchant({
    required String merchantId,
    required String subject,
    required String body,
    required String topic,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendAdminMessageToMerchant');
      await callable.call(<String, dynamic>{
        'merchantId': merchantId,
        'subject': subject,
        'body': body,
        'topic': topic,
      });
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? 'Az admin uzenet kuldese nem sikerult.');
    }
  }

  Future<void> markMessageRead({
    required String userId,
    required String messageId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('adminMessages')
        .doc(messageId)
        .update({'readAt': FieldValue.serverTimestamp()});
  }
}
