import 'package:cloud_firestore/cloud_firestore.dart';

class PostSharersModel {
  final String userID;
  final int timestamp;
  final String sharedPostID;

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _asString(Object? value) => (value ?? '').toString();

  PostSharersModel({
    required this.userID,
    required this.timestamp,
    required this.sharedPostID,
  });

  factory PostSharersModel.fromMap(Map<String, dynamic> data) {
    return PostSharersModel(
      userID: _asString(data['userID']),
      timestamp: _asInt(data['timestamp']),
      sharedPostID: _asString(data['sharedPostID']),
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
