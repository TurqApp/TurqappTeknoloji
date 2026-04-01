part of 'chat_listing.dart';

extension ChatListingShellContentPart on _ChatListingState {
  Future<void> _archiveChat(ChatListingModel item) async {
    await controller.setArchived(item, archived: true);
  }

  Future<void> _unarchiveChat(ChatListingModel item) async {
    await controller.setArchived(item, archived: false);
  }

  Widget _buildPageContent(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenChat),
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      CupertinoIcons.back,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'chat.list_title'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontFamily: "MontserratBold",
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          key: const ValueKey(
                            IntegrationTestKeys.actionChatCreate,
                          ),
                          onTap: controller.showCreateChatBottomSheet,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFF23C15F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ChatSearchField(controller: controller.search),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Container(
                height: 44,
                color: Colors.white,
                child: Row(
                  children: [
                    _TopTab(
                      label: 'chat.tab_all'.tr,
                      integrationKey: IntegrationTestKeys.chatTabAll,
                      active: controller.selectedTab.value == "all",
                      onTap: () => controller.setTab("all"),
                    ),
                    _TopTab(
                      label: 'chat.tab_unread'.tr,
                      integrationKey: IntegrationTestKeys.chatTabUnread,
                      active: controller.selectedTab.value == "unread",
                      onTap: () => controller.setTab("unread"),
                    ),
                    _TopTab(
                      label: 'chat.tab_archive'.tr,
                      integrationKey: IntegrationTestKeys.chatTabArchive,
                      active: controller.selectedTab.value == "archive",
                      onTap: () => controller.setTab("archive"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(child: _buildListBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody() {
    return Obx(() {
      final isSearching = controller.search.text.isNotEmpty;
      final hasResults = controller.filteredList.isNotEmpty;

      return RefreshIndicator(
        onRefresh: () async {
          controller.list.clear();
          await controller.getList();
        },
        backgroundColor: Colors.black,
        color: Colors.white,
        child: controller.waiting.value
            ? const Center(child: CupertinoActivityIndicator())
            : !hasResults
                ? (isSearching
                    ? EmptyRow(text: 'common.no_results'.tr)
                    : _EmptyChatsState())
                : ListView.builder(
                    itemCount: controller.filteredList.length,
                    itemBuilder: (context, index) {
                      final item = controller.filteredList[index];
                      return _buildChatTile(item, isSearching);
                    },
                  ),
      );
    });
  }

  Widget _buildChatTile(ChatListingModel item, bool isSearching) {
    return _SwipeActionTile(
      key: ValueKey(IntegrationTestKeys.chatTile(item.chatID)),
      tileId: item.chatID,
      openedId: _openedChatId,
      isArchiveTab: controller.selectedTab.value == "archive",
      onArchive: () => _handleArchiveAction(item),
      onDelete: () => _handleDeleteAction(item),
      child: ChatListingContent(
        model: item,
        isSearchResult: isSearching,
        isArchiveTab: controller.selectedTab.value == "archive",
      ),
    );
  }

  Future<void> _handleArchiveAction(ChatListingModel item) async {
    try {
      if (controller.selectedTab.value == "archive") {
        await _unarchiveChat(item);
        AppSnackbar(
          'common.done'.tr,
          'chat.unarchived'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await _archiveChat(item);
        AppSnackbar(
          'common.done'.tr,
          'chat.archived'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'chat.action_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      await controller.getList();
    } catch (_) {}
  }

  Future<void> _handleDeleteAction(ChatListingModel item) async {
    bool confirmed = false;
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
    await controller.deleteChat(item);
    AppSnackbar(
      'chat.deleted_title'.tr,
      'chat.deleted_body'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
