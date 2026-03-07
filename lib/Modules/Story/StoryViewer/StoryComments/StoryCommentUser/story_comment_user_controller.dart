import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

class StoryCommentUserController extends GetxController {
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var fullName = "".obs;

  Future<void> getUserData(String userID) async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) async {
      final data = doc.data() ?? <String, dynamic>{};
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
