import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListingContent/chat_listing_content.dart';

import 'chat_listing_controller.dart';

class ChatListing extends StatelessWidget {
  ChatListing({super.key});
  final controller = Get.put(ChatListingController());
  final ValueNotifier<String?> _openedChatId = ValueNotifier<String?>(null);
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _archiveChat(ChatListingModel item) async {
    final db = FirebaseFirestore.instance;
    await db
        .collection("users")
        .doc(_uid)
        .collection("chatArchives")
        .doc(item.userID)
        .set({
      "userID": item.userID,
      "chatID": item.chatID,
      "archived": true,
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    try {
      await db.collection("conversations").doc(item.chatID).set({
        "archived.$_uid": true,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _unarchiveChat(ChatListingModel item) async {
    final db = FirebaseFirestore.instance;

    await db
        .collection("users")
        .doc(_uid)
        .collection("chatArchives")
        .doc(item.userID)
        .set({
      "userID": item.userID,
      "chatID": item.chatID,
      "archived": false,
      "updatedDate": DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    try {
      await db.collection("conversations").doc(item.chatID).set({
        "archived.$_uid": false,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Expanded(
                    child: Text(
                      "Sohbetler",
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
              child: Container(
                height: 40,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller.search,
                    decoration: const InputDecoration(
                      hintText: "Ara",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: "MontserratMedium",
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        CupertinoIcons.search,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
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
                      label: "Tümü",
                      active: controller.selectedTab.value == "all",
                      onTap: () => controller.setTab("all"),
                    ),
                    _TopTab(
                      label: "Okunmamış",
                      active: controller.selectedTab.value == "unread",
                      onTap: () => controller.setTab("unread"),
                    ),
                    _TopTab(
                      label: "Arşiv",
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
                              ? EmptyRow(text: "Arama sonucu bulunamadı")
                              : _EmptyChatsState())
                          : ListView.builder(
                              itemCount: controller.filteredList.length,
                              itemBuilder: (context, index) {
                                final item = controller.filteredList[index];

                                return _SwipeActionTile(
                                  key: ValueKey(item.chatID),
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
                                          "Tamamlandı",
                                          "Sohbet arşivden çıkarıldı",
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      } else {
                                        await _archiveChat(item);
                                        AppSnackbar(
                                          "Arşive Taşındı",
                                          "Sohbet arşive taşındı",
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    } catch (_) {
                                      AppSnackbar(
                                        "Hata",
                                        "İşlem tamamlanamadı, yetki veya kayıt sorunu var",
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
                                      title: "Sohbeti Sil",
                                      message:
                                          "Bu sohbeti silmek istediğinizden emin misiniz?",
                                      cancelText: "Vazgeç",
                                      yesText: "Sohbeti Sil",
                                      yesButtonColor:
                                          CupertinoColors.destructiveRed,
                                      onYesPressed: () {
                                        confirmed = true;
                                      },
                                    );
                                    if (!confirmed) return;
                                    await controller.deleteChat(item);
                                    AppSnackbar(
                                      "Sohbet Silindi",
                                      "Seçilen sohbet başarıyla silindi",
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
                          widget.isArchiveTab ? "Arşivden çıkart" : "Arşivle",
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
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.delete,
                            color: Colors.white, size: 20),
                        SizedBox(height: 4),
                        Text(
                          "Sil",
                          style: TextStyle(
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
  final bool active;
  final VoidCallback? onTap;
  const _TopTab({
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
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
          children: const [
            Icon(
              CupertinoIcons.chat_bubble_2,
              size: 56,
              color: Color(0xFFB8BEC5),
            ),
            SizedBox(height: 14),
            Text(
              "Henüz sohbetin yok",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontFamily: "MontserratSemiBold",
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Mesajlaştığında konuşmaların burada listelenecek.",
              textAlign: TextAlign.center,
              style: TextStyle(
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
