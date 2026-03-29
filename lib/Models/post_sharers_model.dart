import 'package:cloud_firestore/cloud_firestore.dart';

class PostSharersModel {
  final String userID;
  final int timestamp;
  final String sharedPostID;

  PostSharersModel({
    required this.userID,
    required this.timestamp,
    required this.sharedPostID,
  });

  factory PostSharersModel.fromMap(Map<String, dynamic> data) {
    return PostSharersModel(
      userID: (data['userID'] ?? '').toString(),
      timestamp: (data['timestamp'] as num?)?.toInt() ??
          int.tryParse((data['timestamp'] ?? '').toString()) ??
          0,
      sharedPostID: (data['sharedPostID'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timestamp': timestamp,
      'sharedPostID': sharedPostID,
    };
  }

  factory PostSharersModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostSharersModel.fromMap(data);
  }
}
