import 'package:cloud_firestore/cloud_firestore.dart';

class AppFirestore {
  const AppFirestore._();

  static FirebaseFirestore get instance => FirebaseFirestore.instance;
}
