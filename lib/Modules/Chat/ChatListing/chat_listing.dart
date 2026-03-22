import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListingContent/chat_listing_content.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'chat_search_field.dart';
import 'chat_listing_controller.dart';

class ChatListing extends StatefulWidget {
  const ChatListing({super.key});

  @override
  State<ChatListing> createState() => _ChatListingState();
}

class _ChatListingState extends State<ChatListing> {
  late final ChatListingController controller;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final ValueNotifier<String?> _openedChatId = ValueNotifier<String?>(null);
  bool _ownsController = false;

  String get _uid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    final existingController = ChatListingController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ChatListingController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _openedChatId.dispose();
    if (_ownsController &&
        identical(ChatListingController.maybeFind(), controller)) {
      Get.delete<ChatListingController>(force: true);
    }
    super.dispose();
  }

  Future<void> _archiveChat(ChatListingModel item) async {
    await _conversationRepository.setArchived(
      currentUid: _uid,
      otherUserId: item.userID,
      chatId: item.chatID,
      archived: true,
    );
  }

  Future<void> _unarchiveChat(ChatListingModel item) async {
    await _conversationRepository.setArchived(
      currentUid: _uid,
      otherUserId: item.userID,
      chatId: item.chatID,
      archived: false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(CupertinoIcons.back,
                        size: 24, color: Colors.black),
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
                            child: const Icon(CupertinoIcons.add,
                                size: 16, color: Colors.white),
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
              child: ChatSearchField(
                controller: controller.search,
              ),
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
            Expanded(
              child: Obx(() {
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

                                return _SwipeActionTile(
                                  key: ValueKey(
                                    IntegrationTestKeys.chatTile(item.chatID),
                                  ),
                                  tileId: item.chatID,
                                  openedId: _openedChatId,
                                  isArchiveTab:
                                      controller.selectedTab.value == "archive",
                                  onArchive: () async {
                                    try {
                                      if (controller.selectedTab.value ==
                                          "archive") {
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
                                  },
                                  onDelete: () async {
                                    bool confirmed = false;
                                    await noYesAlert(
                                      title: 'chat.delete_title'.tr,
                                      message: 'chat.delete_message'.tr,
                                      cancelText: 'common.cancel'.tr,
                                      yesText: 'chat.delete_confirm'.tr,
                                      yesButtonColor:
                                          CupertinoColors.destructiveRed,
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
                                  },
                                  child: ChatListingContent(
                                    model: item,
                                    isSearchResult: isSearching,
                                    isArchiveTab:
                                        controller.selectedTab.value ==
                                            "archive",
                                  ),
                                );
                              },
                            ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeActionTile extends StatefulWidget {
  final String tileId;
  final ValueNotifier<String?> openedId;
  final bool isArchiveTab;
  final Widget child;
  final Future<void> Function() onDelete;
  final Future<void> Function() onArchive;

  const _SwipeActionTile({
    super.key,
    required this.tileId,
    required this.openedId,
    this.isArchiveTab = false,
    required this.child,
    required this.onDelete,
    required this.onArchive,
  });

  @override
  State<_SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<_SwipeActionTile> {
  double _offsetX = 0;
  bool _busy = false;
  Timer? _autoCloseTimer;

  double _maxReveal(BuildContext context) =>
      MediaQuery.of(context).size.width / 5;

  Future<void> _handleArchive() async {
    if (_busy) return;
    _autoCloseTimer?.cancel();
    debugPrint("[SwipeArchive] tapped tile=${widget.tileId}");
    setState(() => _busy = true);
    await widget.onArchive();
    if (mounted) {
      setState(() {
        _busy = false;
        _offsetX = 0;
      });
      widget.openedId.value = null;
    }
  }

  Future<void> _handleDelete() async {
    if (_busy) return;
    _autoCloseTimer?.cancel();
    setState(() => _busy = true);
    await widget.onDelete();
    if (mounted) {
      setState(() {
        _busy = false;
        _offsetX = 0;
      });
      widget.openedId.value = null;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.openedId.addListener(_onOpenChanged);
  }

  @override
  void didUpdateWidget(covariant _SwipeActionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openedId != widget.openedId) {
      oldWidget.openedId.removeListener(_onOpenChanged);
      widget.openedId.addListener(_onOpenChanged);
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    widget.openedId.removeListener(_onOpenChanged);
    super.dispose();
  }

  void _onOpenChanged() {
    final currentOpen = widget.openedId.value;
    if (currentOpen != null && currentOpen != widget.tileId && _offsetX != 0) {
      if (mounted) setState(() => _offsetX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reveal = _maxReveal(context);
    final isArchiveOpen = _offsetX > 0;
    final isDeleteOpen = _offsetX < 0;

    return ClipRect(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              _autoCloseTimer?.cancel();
              if (widget.openedId.value != null &&
                  widget.openedId.value != widget.tileId) {
                widget.openedId.value = widget.tileId;
              }
              final next = (_offsetX + (details.primaryDelta ?? 0))
                  .clamp(-reveal, reveal);
              setState(() => _offsetX = next);
            },
            onHorizontalDragEnd: (_) {
              final threshold = reveal * 0.35;
              if (_offsetX.abs() < threshold) {
                setState(() {
                  _offsetX = 0;
                });
                widget.openedId.value = null;
                _autoCloseTimer?.cancel();
                return;
              }
              setState(() => _offsetX = _offsetX > 0 ? reveal : -reveal);
              widget.openedId.value = widget.tileId;
              _autoCloseTimer?.cancel();
              _autoCloseTimer = Timer(const Duration(seconds: 2), () {
                if (!mounted || _busy) return;
                setState(() => _offsetX = 0);
                widget.openedId.value = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_offsetX, 0, 0),
              child: Container(
                color: Colors.white,
                child: widget.child,
              ),
            ),
          ),
          if (isArchiveOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: reveal,
              child: Material(
                color: widget.isArchiveTab
                    ? const Color(0xFF2D8CFF)
                    : Colors.black,
                child: InkWell(
                  onTap: _handleArchive,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.archivebox,
                            color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          widget.isArchiveTab
                              ? 'common.unarchive'.tr
                              : 'common.archive'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: "MontserratSemiBold",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (isDeleteOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: reveal,
              child: Material(
                color: const Color(0xFFE53935),
                child: InkWell(
                  onTap: _handleDelete,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.delete,
                            color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'common.delete'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: "MontserratSemiBold",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final String? integrationKey;
  final bool active;
  final VoidCallback? onTap;
  const _TopTab({
    required this.label,
    this.integrationKey,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        key: integrationKey == null ? null : ValueKey(integrationKey!),
        onTap: onTap,
        child: Container(
          height: 44,
          color: Colors.white,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily:
                        active ? "MontserratSemiBold" : "MontserratMedium",
                  ),
                ),
              ),
              if (active)
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_2,
              size: 56,
              color: Color(0xFFB8BEC5),
            ),
            const SizedBox(height: 14),
            Text(
              'chat.empty_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontFamily: "MontserratSemiBold",
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'chat.empty_body'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7A8087),
                fontSize: 14,
                fontFamily: "MontserratMedium",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
