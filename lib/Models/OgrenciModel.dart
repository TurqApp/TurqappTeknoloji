// 📁 lib/Models/OgrenciModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciModel {
  final String userID;
  final String firstName;
  final String lastName;
  final String pfImage;
  final String nickname;

  OgrenciModel({
    required this.userID,
    required this.firstName,
    required this.lastName,
    required this.pfImage,
    required this.nickname,
  });

  /// Eski fromMap fabrika korunuyor
  factory OgrenciModel.fromMap(String id, Map<String, dynamic> data) {
    return OgrenciModel(
      userID: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      pfImage: data['pfImage'] ?? '',
      nickname: data['nickname'] ?? '',
    );
  }

  factory OgrenciModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OgrenciModel.fromMap(doc.id, data);
  }
}
