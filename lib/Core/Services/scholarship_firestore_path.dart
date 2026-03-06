import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarshipFirestorePath {
  ScholarshipFirestorePath._();

  static CollectionReference<Map<String, dynamic>> collection({
    FirebaseFirestore? firestore,
  }) {
    final db = firestore ?? FirebaseFirestore.instance;
    return db.collection('catalog').doc('education').collection('scholarships');
  }

  static DocumentReference<Map<String, dynamic>> doc(
    String docId, {
    FirebaseFirestore? firestore,
  }) {
    return collection(firestore: firestore).doc(docId);
  }
}
