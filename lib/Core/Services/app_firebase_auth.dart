import 'package:firebase_auth/firebase_auth.dart';

class AppFirebaseAuth {
  const AppFirebaseAuth._();

  static FirebaseAuth get instance => FirebaseAuth.instance;
}
