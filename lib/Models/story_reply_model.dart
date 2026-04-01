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

  static DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      final asInt = int.tryParse(value.trim());
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      final asDate = DateTime.tryParse(value.trim());
      if (asDate != null) return asDate;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Firestore DocumentSnapshot'tan model oluşturur
  factory StoryReplyModel.fromDocument(DocumentSnapshot doc) {
    final raw = doc.data();
    final data =
        raw is Map ? raw.cast<String, dynamic>() : const <String, dynamic>{};
    return StoryReplyModel(
      docID: doc.id,
      userID: (data['userID'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      timeStamp: _asDateTime(data['timeStamp']),
    );
  }

  /// (İstersen) gelecekte yazma işlemleri için toJson ekleyebilirsin
  Map<String, dynamic> toJson() => {
        'userID': userID,
        'message': message,
        'timeStamp': timeStamp.millisecondsSinceEpoch,
      };
}
