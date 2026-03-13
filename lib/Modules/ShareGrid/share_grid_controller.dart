import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';

import '../Chat/ChatListing/chat_listing_controller.dart';

class ShareGridController extends GetxController {
  String postID;
  String postType;
  ShareGridController({required this.postType, required this.postID});
  TextEditingController search = TextEditingController();
  RxList<OgrenciModel> followings = <OgrenciModel>[].obs;
  var selectedUser = Rx<OgrenciModel?>(null);
  Rx<FocusNode> searchFocus = FocusNode().obs;
  final chatListingController = Get.put(ChatListingController());
  final UserRepository _userRepository = UserRepository.ensure();
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    searchFocus.value.addListener(() => searchFocus.refresh());
    getFolowers();
  }

  Future<void> getFolowers() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final ids = await _followRepository.getFollowingIds(currentUid);
    final limitedIds = ids.take(20).toList();
    final profiles = await _userRepository.getUsersRaw(limitedIds);
    final items = <OgrenciModel>[];
    for (final userId in limitedIds) {
      final data = profiles[userId];
      if (data == null) continue;
      items.add(OgrenciModel(
        userID: userId,
        firstName: (data["firstName"] ?? "").toString(),
        avatarUrl: (data["avatarUrl"] ?? "").toString(),
        lastName: (data["lastName"] ?? "").toString(),
        nickname: (data["nickname"] ??
                data["username"] ??
                data["displayName"] ??
                "")
            .toString(),
      ));
    }
    followings.assignAll(items);
  }

  Future<void> sendIt() async {
    final selected = selectedUser.value;
    if (selected == null) {
      AppSnackbar("Uyarı", "Önce bir kullanıcı seç");
      return;
    }
    final userID = selected.userID;
    final sohbet = chatListingController.list.firstWhereOrNull(
      (val) => val.userID == userID,
    );
    final currentUID = FirebaseAuth.instance.currentUser!.uid;
    final chatId = sohbet?.chatID ?? buildConversationId(currentUID, userID);

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await _conversationRepository.ensureConversationForPostShare(
        chatId: chatId,
        currentUid: currentUID,
        otherUid: userID,
        nowMs: nowMs,
      );

      await _conversationRepository.addPostShareMessage(
        chatId: chatId,
        currentUid: currentUID,
        postId: postID,
        postType: postType,
      );

      search.text = "";
      searchFocus.value.unfocus();
      selectedUser.value = null;
      Get.back();
      AppSnackbar("Gönderildi", "Gönderi iletildi");
      chatListingController.getList();
    } catch (e) {
      AppSnackbar("Hata", "Gönderilemedi: $e");
    }
  }

  Future<void> searchUser(String keyword) async {
    if (keyword.trim().isEmpty) {
      followings.clear();
      getFolowers();
      return;
    }

    final results = await _userRepository.searchUsersByNicknamePrefix(
      keyword,
      limit: 20,
    );

    followings.assignAll(
      results
          .map((raw) => OgrenciModel.fromMap(
                (raw['id'] ?? '').toString(),
                raw,
              ))
          .where((user) => user.userID.isNotEmpty)
          .toList(growable: false),
    );
  }
}
