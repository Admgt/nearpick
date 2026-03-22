class AppConfig {
  static const String _webPushVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  static String? get webPushVapidKey =>
      _webPushVapidKey.isEmpty ? null : _webPushVapidKey;
}
