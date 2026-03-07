import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class FollowerController extends GetxController {
  var avatarUrl = "".obs;
  var nickname = "".obs;
  var fullname = "".obs;
  var isLoaded = false.obs;
  var isFollowed = false.obs;
  var followLoading = false.obs;

  String _resolveAvatar(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    return (data['avatarUrl'] ??
            data['avatarUrl'] ??
            profile['avatarUrl'] ??
            profile['avatarUrl'] ??
            '')
        .toString()
        .trim();
  }

  String _resolveNickname(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    return (data['nickname'] ??
            profile['nickname'] ??
            data['username'] ??
            profile['username'] ??
            data['usernameLower'] ??
            profile['usernameLower'] ??
            '')
        .toString()
        .trim();
  }

  String _resolveFullName(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    final firstName =
        (data['firstName'] ?? profile['firstName'] ?? '').toString().trim();
    final lastName =
        (data['lastName'] ?? profile['lastName'] ?? '').toString().trim();
    return '$firstName $lastName'.trim();
  }

  Future<void> getData(String userID) async {
    if (isLoaded.value) return;

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(userID).get();
    final data = Map<String, dynamic>.from(userDoc.data() ?? const {});
    if (data.isNotEmpty) {
      if (_resolveAvatar(data).isEmpty ||
          _resolveNickname(data).isEmpty ||
          _resolveFullName(data).isEmpty) {
        try {
          final profileInfo = await FirebaseFirestore.instance
              .collection("users")
              .doc(userID)
              .collection("profile")
              .doc("info")
              .get();
          if (profileInfo.exists) {
            final info = profileInfo.data() ?? const <String, dynamic>{};
            for (final key in const <String>[
              'avatarUrl',
              'avatarUrl',
              'avatarUrl',
              'avatarUrl',
              'nickname',
              'username',
              'usernameLower',
              'firstName',
              'lastName',
            ]) {
              final current = (data[key] ?? '').toString().trim();
              final incoming = (info[key] ?? '').toString().trim();
              if (current.isEmpty && incoming.isNotEmpty) {
                data[key] = incoming;
              }
            }
          }
        } catch (_) {}
      }

      avatarUrl.value = _resolveAvatar(data);
      nickname.value = _resolveNickname(data);
      fullname.value = _resolveFullName(data);
    }

    isLoaded.value = true;
  }

  Future<void> followControl(String userID) async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection("followings")
        .doc(userID)
        .get()
        .then((doc) {
      isFollowed.value = doc.exists;
    });
  }

  Future<void> follow(String otherUserID) async {
    if (followLoading.value) return;
    final wasFollowed = isFollowed.value;
    isFollowed.value = !wasFollowed; // optimistic
    followLoading.value = true;
    final outcome = await FollowService.toggleFollow(otherUserID);
    isFollowed.value = outcome.nowFollowing; // reconcile
    if (outcome.limitReached) {
      AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
    }
    followLoading.value = false;
  }
}
