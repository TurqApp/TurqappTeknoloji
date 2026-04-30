import 'package:firebase_storage/firebase_storage.dart';

class AppFirebaseStorage {
  const AppFirebaseStorage._();

  static FirebaseStorage get instance => FirebaseStorage.instance;
}
