import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

class StoryCommentUserController extends GetxController {
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var fullName = "".obs;

  bool _needsProfileInfo(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    final avatar = resolveAvatarUrl(data, profile: profile).trim();
    return avatar.isEmpty;
  }

  Future<Map<String, dynamic>> _mergeProfileInfoIfNeeded(
      String userID, Map<String, dynamic> data) async {
    if (!_needsProfileInfo(data)) return data;
    try {
      final infoDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .collection("profile")
          .doc("info")
          .get();
      if (!infoDoc.exists) return data;
      final info = infoDoc.data() ?? const <String, dynamic>{};
      final merged = Map<String, dynamic>.from(data);
      for (final key in const <String>[
        'avatarUrl',
        'avatarUrl',
        'avatarUrl',
        'avatarUrl',
        'nickname',
        'username',
        'firstName',
        'lastName',
      ]) {
        final current = (merged[key] ?? '').toString().trim();
        final incoming = (info[key] ?? '').toString().trim();
        if (current.isEmpty && incoming.isNotEmpty) {
          merged[key] = incoming;
        }
      }
      return merged;
    } catch (_) {
      return data;
    }
  }

  Future<void> getUserData(String userID) async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) async {
      final base = doc.data() ?? <String, dynamic>{};
      final data = await _mergeProfileInfoIfNeeded(userID, base);
      final profile = (data['profile'] is Map)
          ? Map<String, dynamic>.from(data['profile'] as Map)
          : const <String, dynamic>{};
      nickname.value = (data['nickname'] ??
              profile['nickname'] ??
              data['username'] ??
              profile['username'] ??
              '')
          .toString();
      final firstName =
          (data['firstName'] ?? profile['firstName'] ?? '').toString();
      final lastName =
          (data['lastName'] ?? profile['lastName'] ?? '').toString();
      fullName.value = '$firstName $lastName'.trim();
      avatarUrl.value = resolveAvatarUrl(data, profile: profile);
    });
  }
}
