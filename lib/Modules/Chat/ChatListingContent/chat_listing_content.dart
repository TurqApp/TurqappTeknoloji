import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/chat_constants.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_listing_content_controller.dart';

class ChatListingContent extends StatelessWidget {
  static const Set<String> _postMessageMarkers = {
    'gönderi',
    kConversationPostMessageMarker,
    'chat.post',
    'post',
    'beitrag',
    'publication',
    'pubblicazione',
    'пост',
  };

  final ChatListingModel model;
  final bool isSearchResult;
  final bool isArchiveTab;
  ChatListingContent({
    super.key,
    required this.model,
    this.isSearchResult = false,
    this.isArchiveTab = false,
  });
  late final ChatListingContentController controller;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final GlobalKey _timeAnchorKey = GlobalKey();

  String _buildSubtitle() {
    if (model.lastMessage.trim().isNotEmpty) {
      if (_postMessageMarkers.contains(
        normalizeSearchText(model.lastMessage),
      )) {
        return 'chat.post'.tr;
      }
      return model.lastMessage.trim();
    }
    if (controller.lastMessage.isEmpty) return 'chat.tap_to_chat'.tr;
    final last = controller.lastMessage.last;
    if (last.metin.trim().isNotEmpty) return last.metin.trim();
    if (last.imgs.isNotEmpty) return 'chat.photo'.tr;
    return 'chat.message_label'.tr;
  }

  String _buildTimeText() {
    final ts = int.tryParse(model.timeStamp) ?? 0;
    if (ts <= 0) return "";
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return "$h:$m";
    }
    return "${dt.day}.${dt.month}.${dt.year}";
  }

  String get _uid => CurrentUserService.instance.effectiveUserId;

  Future<void> _refreshList() async {
    await ChatListingController.maybeFind()?.getList();
  }

  Future<void> _markUnread() async {
    await _conversationRepository.setUnreadCount(
      chatId: model.chatID,
      currentUid: _uid,
      unreadCount: 1,
    );
    await _refreshList();
    AppSnackbar('common.done'.tr, 'chat.marked_unread'.tr);
  }

  Future<void> _togglePinned() async {
    final newValue = !model.isPinned;
    if (newValue) {
      final listing = ChatListingController.maybeFind();
      if (listing == null) return;
      final pinnedCount = listing.list
          .where((e) => e.isPinned && !e.deleted.contains("__archived__"))
          .length;
      if (pinnedCount >= 5) {
        AppSnackbar('chat.limit_title'.tr, 'chat.pin_limit'.tr);
        return;
      }
    }
    await _conversationRepository.setPinned(
      chatId: model.chatID,
      currentUid: _uid,
      pinned: newValue,
    );
    await _refreshList();
    AppSnackbar('common.done'.tr, 'chat.action_completed'.tr);
  }

  Future<void> _toggleMuted() async {
    final newValue = !model.isMuted;
    await _conversationRepository.setMuted(
      chatId: model.chatID,
      currentUid: _uid,
      muted: newValue,
    );
    await _refreshList();
    AppSnackbar(
        'common.done'.tr, newValue ? 'chat.muted'.tr : 'chat.unmuted'.tr);
  }

  Future<void> _archiveChat() async {
    await _conversationRepository.setArchived(
      currentUid: _uid,
      otherUserId: model.userID,
      chatId: model.chatID,
      archived: true,
    );

    await _refreshList();
    AppSnackbar('common.done'.tr, 'chat.archived'.tr);
  }

  Future<void> _unarchiveChat() async {
    await _conversationRepository.setArchived(
      currentUid: _uid,
      otherUserId: model.userID,
      chatId: model.chatID,
      archived: false,
    );

    await _refreshList();
    AppSnackbar('common.done'.tr, 'chat.unarchived'.tr);
  }

  Future<void> _deleteChat() async {
    var confirmed = false;
    await noYesAlert(
      title: 'chat.delete_title'.tr,
      message: 'chat.delete_message'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'chat.delete_confirm'.tr,
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () {
        confirmed = true;
      },
    );
    if (!confirmed) return;
    final chatListing = ChatListingController.maybeFind();
    if (chatListing != null) {
      await chatListing.deleteChat(model);
    }
    AppSnackbar('chat.deleted_title'.tr, 'chat.deleted_body'.tr);
  }

  Future<void> _showAnchoredMenu(BuildContext context) async {
    final anchorBox =
        _timeAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;
    final anchorGlobal = anchorBox != null
        ? anchorBox.localToGlobal(anchorBox.size.center(Offset.zero))
        : Offset(screenSize.width - 24, screenSize.height / 2);

    final openUp = anchorGlobal.dy > (screenSize.height * 0.60);
    final anchorRect = Rect.fromCenter(
      center: Offset(anchorGlobal.dx - 6, anchorGlobal.dy + (openUp ? -6 : 6)),
      width: 2,
      height: 2,
    );

    showPullDownMenu(
      context: context,
      position: anchorRect,
      items: isArchiveTab
          ? [
              PullDownMenuItem(
                title: model.isMuted ? 'chat.unmute'.tr : 'chat.mute'.tr,
                icon: CupertinoIcons.bell_slash,
                onTap: () {
                  _toggleMuted();
                },
              ),
              PullDownMenuItem(
                title: 'common.unarchive'.tr,
                icon: CupertinoIcons.archivebox_fill,
                onTap: () {
                  _unarchiveChat();
                },
              ),
              PullDownMenuItem(
                title: 'common.delete'.tr,
                icon: CupertinoIcons.delete,
                isDestructive: true,
                onTap: () {
                  _deleteChat();
                },
              ),
            ]
          : [
              PullDownMenuItem(
                title: 'chat.mark_unread'.tr,
                icon: CupertinoIcons.mail,
                onTap: () {
                  _markUnread();
                },
              ),
              PullDownMenuItem(
                title: model.isPinned ? 'chat.unpin'.tr : 'chat.pin'.tr,
                icon: CupertinoIcons.pin,
                onTap: () {
                  _togglePinned();
                },
              ),
              PullDownMenuItem(
                title: model.isMuted ? 'chat.unmute'.tr : 'chat.mute'.tr,
                icon: CupertinoIcons.bell_slash,
                onTap: () {
                  _toggleMuted();
                },
              ),
              PullDownMenuItem(
                title: 'common.archive'.tr,
                icon: CupertinoIcons.archivebox,
                onTap: () {
                  _archiveChat();
                },
              ),
              PullDownMenuItem(
                title: 'common.delete'.tr,
                icon: CupertinoIcons.delete,
                isDestructive: true,
                onTap: () {
                  _deleteChat();
                },
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    controller = ChatListingContentController.ensure(
      userID: model.userID,
      model: model,
      tag: model.chatID,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Get.to(() => SocialProfile(userID: model.userID));
                },
                child: ClipOval(
                  child: SizedBox(
                    width: isSearchResult ? 40 : 50,
                    height: isSearchResult ? 40 : 50,
                    child: model.avatarUrl != ""
                        ? CachedNetworkImage(
                            imageUrl: model.avatarUrl,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: CupertinoActivityIndicator(
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() {
                  final isUnread = controller.notReadCounter.value > 0;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: isSearchResult
                        ? null
                        : () async {
                            await _showAnchoredMenu(context);
                          },
                    onTap: () async {
                      final nowMs = DateTime.now().millisecondsSinceEpoch;
                      final rowTs = int.tryParse(model.timeStamp) ?? 0;
                      final seenAtMs = rowTs > nowMs ? rowTs : nowMs;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt(
                        "chat_last_opened_${_uid}_${model.chatID}",
                        seenAtMs,
                      );
                      controller.notReadCounter.value = 0;
                      model.unreadCount = 0;
                      UnreadMessagesController.maybeFind()
                          ?.updateConversationUnreadLocal(
                        otherUid: model.userID,
                        unreadCount: 0,
                        chatId: model.chatID,
                        seenAtMs: seenAtMs,
                      );
                      InAppNotificationsController.maybeFind()
                          ?.markChatNotificationsReadLocal(
                        chatId: model.chatID,
                      );
                      unawaited(_conversationRepository
                          .setUnreadCount(
                            chatId: model.chatID,
                            currentUid: _uid,
                            unreadCount: 0,
                          )
                          .catchError((_) {}));
                      await Get.to(() =>
                          ChatView(chatID: model.chatID, userID: model.userID));
                      await ChatListingController.maybeFind()?.getList();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                model.nickname,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: isSearchResult ? 15 : 16,
                                  fontFamily: isUnread
                                      ? "MontserratBold"
                                      : (isSearchResult
                                          ? "MontserratMedium"
                                          : "MontserratSemiBold"),
                                  height: 1.05,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            RozetContent(size: 14, userID: controller.userID),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isSearchResult
                                    ? (model.fullName.trim().isEmpty
                                        ? _buildSubtitle()
                                        : model.fullName.trim())
                                    : _buildSubtitle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isUnread
                                      ? const Color(0xFF101418)
                                      : const Color(0xFF6B7179),
                                  fontSize: isSearchResult ? 13 : 14,
                                  fontFamily: isUnread
                                      ? "MontserratBold"
                                      : "MontserratMedium",
                                ),
                              ),
                            ),
                            if (model.isMuted && !isSearchResult)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  'chat.muted_label'.tr,
                                  style: const TextStyle(
                                    color: Color(0xFF8A9199),
                                    fontSize: 11,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              if (!isSearchResult)
                Obx(() {
                  final isUnread = controller.notReadCounter.value > 0;
                  return Column(
                    key: _timeAnchorKey,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (model.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Icon(
                            CupertinoIcons.pin_fill,
                            size: 12,
                            color: Color(0xFF6B7179),
                          ),
                        ),
                      Text(
                        _buildTimeText(),
                        style: TextStyle(
                          color: isUnread
                              ? const Color(0xFF101418)
                              : const Color(0xFF6B7179),
                          fontSize: 13,
                          fontFamily: isUnread
                              ? "MontserratSemiBold"
                              : "MontserratMedium",
                        ),
                      ),
                      const SizedBox(height: 8),
                      controller.notReadCounter.value >= 1
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF18A558),
                                shape: BoxShape.circle,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  );
                }),
              if (isSearchResult)
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.blueAccent,
                  size: 15,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        if (isSearchResult)
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 65),
            child: SizedBox(
              height: 1,
              child: Divider(color: Colors.grey.withAlpha(20)),
            ),
          )
        else
          const SizedBox(height: 2),
      ],
    );
  }
}
