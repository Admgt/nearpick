import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> initAndSaveToken({String? vapidKey}) async {
    await _messaging.requestPermission();

    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken(vapidKey: vapidKey);
    if (token == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': 'flutter',
    });

    _messaging.onTokenRefresh.listen((newToken) async {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(newToken)
          .set({
        'token': newToken,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
    });
  }
}
