// 📁 lib/Models/ogrenci_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

class OgrenciModel {
  final String userID;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final String nickname;

  OgrenciModel({
    required this.userID,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.nickname,
  });

  /// Eski fromMap fabrika korunuyor
  factory OgrenciModel.fromMap(String id, Map<String, dynamic> data) {
    return OgrenciModel(
      userID: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      avatarUrl: resolveAvatarUrl(data),
      nickname:
          (data['nickname'] ?? data['username'] ?? data['displayName'] ?? '')
              .toString(),
    );
  }

  factory OgrenciModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OgrenciModel.fromMap(doc.id, data);
  }
}
