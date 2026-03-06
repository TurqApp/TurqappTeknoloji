// lib/Models/story_reply_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryReplyModel {
  String docID;
  String message;
  DateTime timeStamp;
  String userID;

  StoryReplyModel({
    required this.docID,
    required this.userID,
    required this.message,
    required this.timeStamp,
  });

  /// Firestore DocumentSnapshot'tan model oluşturur
  factory StoryReplyModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryReplyModel(
      docID: doc.id,
      userID: data['userID'] ?? '',
      message: data['message'] ?? '',
      timeStamp: data['timeStamp'] is Timestamp
          ? (data['timeStamp'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (data['timeStamp'] as num?)?.toInt() ?? 0,
            ),
    );
  }

  /// (İstersen) gelecekte yazma işlemleri için toJson ekleyebilirsin
  Map<String, dynamic> toJson() => {
        'userID': userID,
        'message': message,
        'timeStamp': timeStamp.millisecondsSinceEpoch,
      };
}
