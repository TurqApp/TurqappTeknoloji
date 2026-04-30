part of 'chat_listing_content.dart';

extension ChatListingContentViewPart on ChatListingContent {
  Widget _buildTile(BuildContext context) {
    controller = ensureChatListingContentController(
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
              _buildAvatar(context),
              const SizedBox(width: 10),
              Expanded(child: _buildMainContent(context)),
              const SizedBox(width: 8),
              if (!isSearchResult) _buildTrailingMeta() else _buildChevron(),
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

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        const ProfileNavigationService().openSocialProfile(model.userID);
      },
      child: ClipOval(
        child: SizedBox(
          width: isSearchResult ? 40 : 50,
          height: isSearchResult ? 40 : 50,
          child: CachedUserAvatar(
            imageUrl: model.avatarUrl,
            radius: isSearchResult ? 20 : 25,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Obx(() {
      final isUnread = controller.notReadCounter.value > 0;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress:
            isSearchResult ? null : () async => _showAnchoredMenu(context),
        onTap: () => _openChat(context),
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
                          ? 'MontserratBold'
                          : (isSearchResult
                              ? 'MontserratMedium'
                              : 'MontserratSemiBold'),
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
                      fontFamily:
                          isUnread ? 'MontserratBold' : 'MontserratMedium',
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
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrailingMeta() {
    return Obx(() {
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
              color:
                  isUnread ? const Color(0xFF101418) : const Color(0xFF6B7179),
              fontSize: 13,
              fontFamily: isUnread ? 'MontserratSemiBold' : 'MontserratMedium',
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
    });
  }

  Widget _buildChevron() {
    return const Icon(
      CupertinoIcons.chevron_right,
      color: Colors.blueAccent,
      size: 15,
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rowTs = int.tryParse(model.timeStamp) ?? 0;
    final seenAtMs = rowTs > nowMs ? rowTs : nowMs;
    final preferences = ensureLocalPreferenceRepository();
    await preferences.setInt(
      'chat_last_opened_${_uid}_${model.chatID}',
      seenAtMs,
    );
    controller.notReadCounter.value = 0;
    model.unreadCount = 0;
    maybeFindUnreadMessagesController()?.updateConversationUnreadLocal(
      otherUid: model.userID,
      unreadCount: 0,
      chatId: model.chatID,
      seenAtMs: seenAtMs,
    );
    InAppNotificationsController.maybeFind()?.markChatNotificationsReadLocal(
      chatId: model.chatID,
    );
    unawaited(
      _conversationRepository
          .setUnreadCount(
            chatId: model.chatID,
            currentUid: _uid,
            unreadCount: 0,
          )
          .catchError((_) {}),
    );
    await Get.to(() => ChatView(chatID: model.chatID, userID: model.userID));
    await ChatListingController.maybeFind()?.getList();
  }
}
