// lib/Modules/Story/StoryReplies/StorySeensModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StorySeensModel {
  final String userID;
  final int timeStamp; // millisecondsSinceEpoch

  StorySeensModel({
    required this.userID,
    required this.timeStamp,
  });

  /// Firestore’dan DocumentSnapshot ile model oluşturur
  factory StorySeensModel.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final ts = data['timeStamp'];
    return StorySeensModel(
      userID: (data['userID'] ?? doc.id).toString(),
      timeStamp: ts is Timestamp
          ? ts.millisecondsSinceEpoch
          : int.tryParse(ts.toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'timeStamp': Timestamp.fromMillisecondsSinceEpoch(timeStamp),
      };
}
