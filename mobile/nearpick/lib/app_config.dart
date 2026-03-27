import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _webPushVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );
  static const bool _useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
  );
  static const String _firebaseEmulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
  );
  static const int _authEmulatorPort = int.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );
  static const int _firestoreEmulatorPort = int.fromEnvironment(
    'FIREBASE_FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );
  static const int _functionsEmulatorPort = int.fromEnvironment(
    'FIREBASE_FUNCTIONS_EMULATOR_PORT',
    defaultValue: 5001,
  );
  static const int _storageEmulatorPort = int.fromEnvironment(
    'FIREBASE_STORAGE_EMULATOR_PORT',
    defaultValue: 9199,
  );

  static String? get webPushVapidKey =>
      _webPushVapidKey.isEmpty ? null : _webPushVapidKey;

  static bool get useFirebaseEmulators => _useFirebaseEmulators;

  static String get firebaseEmulatorHost {
    if (_firebaseEmulatorHost.trim().isNotEmpty) {
      return _firebaseEmulatorHost.trim();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }

    return '127.0.0.1';
  }

  static int get authEmulatorPort => _authEmulatorPort;
  static int get firestoreEmulatorPort => _firestoreEmulatorPort;
  static int get functionsEmulatorPort => _functionsEmulatorPort;
  static int get storageEmulatorPort => _storageEmulatorPort;

  static Future<void> configureFirebaseRuntime() async {
    if (!useFirebaseEmulators) {
      return;
    }

    final host = firebaseEmulatorHost;

    await FirebaseAuth.instance.useAuthEmulator(host, authEmulatorPort);
    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      firestoreEmulatorPort,
    );
    FirebaseFunctions.instance.useFunctionsEmulator(
      host,
      functionsEmulatorPort,
    );
    FirebaseStorage.instance.useStorageEmulator(host, storageEmulatorPort);
  }
}
