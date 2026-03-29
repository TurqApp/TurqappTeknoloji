// 📁 lib/Models/ogrenci_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedUserModel {
  final String userID;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final String nickname;
  final String bio; // ✱ Yeni alan
  final String rozet;

  RecommendedUserModel({
    required this.userID,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.nickname,
    required this.bio, // ✱ Yapıcıda zorunlu kılındı
    required this.rozet,
  });

  /// Eski fromMap fabrika korunuyor, bio da ekleniyor
  factory RecommendedUserModel.fromMap(String id, Map<String, dynamic> data) {
    return RecommendedUserModel(
      userID: id,
      firstName: (data['firstName'] ?? '').toString(),
      lastName: (data['lastName'] ?? '').toString(),
      avatarUrl: (data['avatarUrl'] ?? '').toString(),
      nickname: (data['nickname'] ?? '').toString(),
      bio: (data['bio'] ?? '').toString(), // ✱ Buradan al
      rozet: (data['rozet'] ?? '').toString(),
    );
  }

  /// Firestore DocumentSnapshot'tan direkt dönmek için
  factory RecommendedUserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RecommendedUserModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'nickname': nickname,
      'bio': bio,
      'rozet': rozet,
    };
  }
}
