import 'package:cloud_firestore/cloud_firestore.dart';

class ViewerModel {
  static num _asNum(Object? value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString()) ?? 0;
  }

  String userID;
  num timeStamp;

  ViewerModel({
    required this.userID,
    required this.timeStamp,
  });

  factory ViewerModel.fromMap(Map<String, dynamic> data) {
    return ViewerModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: _asNum(data['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timeStamp': timeStamp,
    };
  }

  factory ViewerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ViewerModel.fromMap(data);
  }

  factory ViewerModel.create(String userID) {
    return ViewerModel(
      userID: userID,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
