part of 'chat_listing_content.dart';

extension ChatListingContentActionsPart on ChatListingContent {
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
          .where((e) => e.isPinned && !e.deleted.contains('__archived__'))
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
      'common.done'.tr,
      newValue ? 'chat.muted'.tr : 'chat.unmuted'.tr,
    );
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
      items: isArchiveTab ? _buildArchiveMenuItems() : _buildDefaultMenuItems(),
    );
  }

  List<PullDownMenuEntry> _buildArchiveMenuItems() {
    return [
      PullDownMenuItem(
        title: model.isMuted ? 'chat.unmute'.tr : 'chat.mute'.tr,
        icon: CupertinoIcons.bell_slash,
        onTap: _toggleMuted,
      ),
      PullDownMenuItem(
        title: 'common.unarchive'.tr,
        icon: CupertinoIcons.archivebox_fill,
        onTap: _unarchiveChat,
      ),
      PullDownMenuItem(
        title: 'common.delete'.tr,
        icon: CupertinoIcons.delete,
        isDestructive: true,
        onTap: _deleteChat,
      ),
    ];
  }

  List<PullDownMenuEntry> _buildDefaultMenuItems() {
    return [
      PullDownMenuItem(
        title: 'chat.mark_unread'.tr,
        icon: CupertinoIcons.mail,
        onTap: _markUnread,
      ),
      PullDownMenuItem(
        title: model.isPinned ? 'chat.unpin'.tr : 'chat.pin'.tr,
        icon: CupertinoIcons.pin,
        onTap: _togglePinned,
      ),
      PullDownMenuItem(
        title: model.isMuted ? 'chat.unmute'.tr : 'chat.mute'.tr,
        icon: CupertinoIcons.bell_slash,
        onTap: _toggleMuted,
      ),
      PullDownMenuItem(
        title: 'common.archive'.tr,
        icon: CupertinoIcons.archivebox,
        onTap: _archiveChat,
      ),
      PullDownMenuItem(
        title: 'common.delete'.tr,
        icon: CupertinoIcons.delete,
        isDestructive: true,
        onTap: _deleteChat,
      ),
    ];
  }
}
