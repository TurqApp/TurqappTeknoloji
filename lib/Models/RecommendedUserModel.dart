// 📁 lib/Models/OgrenciModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedUserModel {
  final String userID;
  final String firstName;
  final String lastName;
  final String pfImage;
  final String nickname;
  final String bio;        // ✱ Yeni alan

  RecommendedUserModel({
    required this.userID,
    required this.firstName,
    required this.lastName,
    required this.pfImage,
    required this.nickname,
    required this.bio,      // ✱ Yapıcıda zorunlu kılındı
  });

  /// Eski fromMap fabrika korunuyor, bio da ekleniyor
  factory RecommendedUserModel.fromMap(String id, Map<String, dynamic> data) {
    return RecommendedUserModel(
      userID: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      pfImage: data['pfImage'] ?? '',
      nickname: data['nickname'] ?? '',
      bio: data['bio'] ?? '',   // ✱ Buradan al
    );
  }

  /// Firestore DocumentSnapshot'tan direkt dönmek için
  factory RecommendedUserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RecommendedUserModel.fromMap(doc.id, data);
  }
}
