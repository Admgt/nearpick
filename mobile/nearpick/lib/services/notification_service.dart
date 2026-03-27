import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../app_config.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> initAndSaveToken({String? vapidKey}) async {
    if (AppConfig.useFirebaseEmulators) {
      return;
    }

    final normalizedVapidKey = vapidKey?.trim();

    try {
      final settings = await _messaging.requestPermission();
      final status = settings.authorizationStatus;
      if (status == AuthorizationStatus.denied ||
          status == AuthorizationStatus.notDetermined) {
        return;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-blocked') {
        return;
      }
      rethrow;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    if (kIsWeb && (normalizedVapidKey == null || normalizedVapidKey.isEmpty)) {
      return;
    }

    final token = await _messaging.getToken(vapidKey: normalizedVapidKey);
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
