import 'package:firebase_messaging/firebase_messaging.dart';

class AppFirebaseMessaging {
  const AppFirebaseMessaging._();

  static FirebaseMessaging get instance => FirebaseMessaging.instance;

  static void onBackgroundMessage(
    Future<void> Function(RemoteMessage message) handler,
  ) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }
}
