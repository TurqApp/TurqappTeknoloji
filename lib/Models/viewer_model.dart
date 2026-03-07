import 'package:cloud_firestore/cloud_firestore.dart';

class ViewerModel {
  String userID;
  num timeStamp;

  ViewerModel({
    required this.userID,
    required this.timeStamp,
  });

  factory ViewerModel.fromMap(Map<String, dynamic> data) {
    return ViewerModel(
      userID: data['userID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
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
