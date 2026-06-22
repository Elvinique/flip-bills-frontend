import 'dart:developer';

/// Notification service stub.
/// Wire up Firebase Messaging by:
///   1. Adding `firebase_messaging: ^15.0.0` to pubspec.yaml
///   2. Adding `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
///   3. Uncommenting the FirebaseMessaging lines below.
///
/// Until then, the app works without push notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // ── Uncomment once Firebase is set up ────────────────────────────────────
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();
    // final token = await messaging.getToken();
    // log('FCM token: $token');
    // await _registerTokenWithBackend(token);
    //
    // FirebaseMessaging.onMessage.listen((message) {
    //   log('FCM foreground: ${message.notification?.title}');
    //   _showInAppBanner(message);
    // });
    // ─────────────────────────────────────────────────────────────────────────

    log('NotificationService: initialised (stub mode — Firebase not yet configured)');
  }

  /// Call this after login to register the device FCM token with the backend.
  Future<void> registerDeviceToken() async {
    // Placeholder — implement after Firebase setup.
    log('NotificationService.registerDeviceToken: stub');
  }
}
