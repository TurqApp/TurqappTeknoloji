import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../Chat/ChatListing/chat_listing_controller.dart';

class ShareGridController extends GetxController {
  String postID;
  String postType;
  ShareGridController({required this.postType, required this.postID});
  TextEditingController search = TextEditingController();
  RxList<OgrenciModel> followings = <OgrenciModel>[].obs;
  var selectedUser = Rx<OgrenciModel?>(null);
  Rx<FocusNode> searchFocus = FocusNode().obs;
  late final ChatListingController chatListingController =
      Get.isRegistered<ChatListingController>()
          ? Get.find<ChatListingController>()
          : Get.put(ChatListingController());
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  @override
  void onInit() {
    super.onInit();
    searchFocus.value.addListener(() => searchFocus.refresh());
    getFolowers();
  }

  @override
  void onClose() {
    search.dispose();
    searchFocus.value.dispose();
    super.onClose();
  }

  Future<void> getFolowers() async {
    final currentUid = CurrentUserService.instance.userId;
    final ids = await _visibilityPolicy.loadViewerFollowingIds(
      viewerUserId: currentUid,
    );
    final limitedIds = ids.take(20).toList();
    final profiles = await _userSummaryResolver.resolveMany(limitedIds);
    final items = <OgrenciModel>[];
    for (final userId in limitedIds) {
      final data = profiles[userId];
      if (data == null) continue;
      items.add(OgrenciModel(
        userID: userId,
        firstName: data.displayName,
        avatarUrl: data.avatarUrl,
        lastName: '',
        nickname: data.nickname,
      ));
    }
    followings.assignAll(items);
  }

  Future<void> sendIt() async {
    final selected = selectedUser.value;
    if (selected == null) {
      AppSnackbar('common.warning'.tr, 'share_grid.select_user_first'.tr);
      return;
    }
    final userID = selected.userID;
    final sohbet = chatListingController.list.firstWhereOrNull(
      (val) => val.userID == userID,
    );
    final currentUID = CurrentUserService.instance.userId;
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
      AppSnackbar('common.success'.tr, 'share_grid.post_forwarded'.tr);
      chatListingController.getList();
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'share_grid.forward_failed'.trParams({'error': '$e'}),
      );
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
