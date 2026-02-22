import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının bir post ile ilişkisini temsil eden basit model.
class UserPostReference {
  UserPostReference({
    required this.docId,
    required this.postId,
    required this.timeStamp,
  });

  factory UserPostReference.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawTime = data['timeStamp'];
    final parsedTime = rawTime is num
        ? rawTime
        : rawTime is Timestamp
            ? rawTime.millisecondsSinceEpoch
            : 0;
    return UserPostReference(
      docId: doc.id,
      postId: data['post_docID'] as String? ?? doc.id,
      timeStamp: parsedTime,
    );
  }

  final String docId;
  final String postId;
  final num timeStamp;
}
