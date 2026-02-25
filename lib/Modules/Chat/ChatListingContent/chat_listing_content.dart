import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_listing_content_controller.dart';

class ChatListingContent extends StatelessWidget {
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
  final GlobalKey _timeAnchorKey = GlobalKey();

  String _buildSubtitle() {
    if (model.lastMessage.trim().isNotEmpty) return model.lastMessage.trim();
    if (controller.lastMessage.isEmpty) return "Sohbet etmek için dokun.";
    final last = controller.lastMessage.last;
    if (last.metin.trim().isNotEmpty) return last.metin.trim();
    if (last.imgs.isNotEmpty) return "Fotoğraf";
    return "Mesaj";
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

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _refreshList() async {
    if (Get.isRegistered<ChatListingController>()) {
      await Get.find<ChatListingController>().getList();
    }
  }

  Future<void> _markUnread() async {
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(model.chatID)
        .set({
      "unread.$_uid": 1,
    }, SetOptions(merge: true));
    await _refreshList();
    AppSnackbar("Tamamlandı", "Sohbet okunmadı olarak işaretlendi");
  }

  Future<void> _togglePinned() async {
    final newValue = !model.isPinned;
    if (newValue && Get.isRegistered<ChatListingController>()) {
      final listing = Get.find<ChatListingController>();
      final pinnedCount = listing.list
          .where((e) => e.isPinned && !e.deleted.contains("__archived__"))
          .length;
      if (pinnedCount >= 5) {
        AppSnackbar("Limit", "En fazla 5 sohbet sabitlenebilir");
        return;
      }
    }
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(model.chatID)
        .set({
      "pinned.$_uid": newValue,
    }, SetOptions(merge: true));
    await _refreshList();
    AppSnackbar("Tamamlandı", "İşlem tamamlandı");
  }

  Future<void> _toggleMuted() async {
    final newValue = !model.isMuted;
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(model.chatID)
        .set({
      "muted.$_uid": newValue,
    }, SetOptions(merge: true));
    await _refreshList();
    AppSnackbar("Tamamlandı",
        newValue ? "Sohbet sessize alındı" : "Sohbet sesi açıldı");
  }

  Future<void> _archiveChat() async {
    final db = FirebaseFirestore.instance;
    var wrote = false;
    await db
        .collection("users")
        .doc(_uid)
        .collection("chatArchives")
        .doc(model.userID)
        .set({
      "userID": model.userID,
      "chatID": model.chatID,
      "archived": true,
      "updatedAt": DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    wrote = true;

    try {
      final convById =
          await db.collection("conversations").doc(model.chatID).get();
      if (convById.exists) {
        await convById.reference
            .set({"archived.$_uid": true}, SetOptions(merge: true));
        wrote = true;
      }
    } catch (_) {}

    try {
      final convCandidates = await db
          .collection("conversations")
          .where("participants", arrayContains: _uid)
          .get();
      for (final doc in convCandidates.docs) {
        final participants =
            List<String>.from(doc.data()["participants"] ?? []);
        if (participants.contains(model.userID)) {
          await doc.reference
              .set({"archived.$_uid": true}, SetOptions(merge: true));
          wrote = true;
        }
      }
    } catch (_) {}

    if (!wrote) {
      AppSnackbar("Hata", "Arşivleme yetkisi yok veya sohbet kaydı bulunamadı");
      return;
    }
    await _refreshList();
    AppSnackbar("Tamamlandı", "Sohbet arşive taşındı");
  }

  Future<void> _unarchiveChat() async {
    final db = FirebaseFirestore.instance;

    try {
      await db
          .collection("users")
          .doc(_uid)
          .collection("chatArchives")
          .doc(model.userID)
          .set({
        "userID": model.userID,
        "chatID": model.chatID,
        "archived": false,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (_) {}

    try {
      await db.collection("conversations").doc(model.chatID).set({
        "archived.$_uid": false,
      }, SetOptions(merge: true));
    } catch (_) {}

    try {
      final convCandidates = await db
          .collection("conversations")
          .where("participants", arrayContains: _uid)
          .get();
      for (final doc in convCandidates.docs) {
        final participants =
            List<String>.from(doc.data()["participants"] ?? []);
        if (participants.contains(model.userID)) {
          await doc.reference
              .set({"archived.$_uid": false}, SetOptions(merge: true));
        }
      }
    } catch (_) {}

    await _refreshList();
    AppSnackbar("Tamamlandı", "Sohbet arşivden çıkarıldı");
  }

  Future<void> _deleteChat() async {
    var confirmed = false;
    await noYesAlert(
      title: "Sohbeti Sil",
      message: "Bu sohbeti silmek istediğinizden emin misiniz?",
      cancelText: "Vazgeç",
      yesText: "Sohbeti Sil",
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () {
        confirmed = true;
      },
    );
    if (!confirmed) return;

    await FirebaseFirestore.instance
        .collection("conversations")
        .doc(model.chatID)
        .set({
      "archived.$_uid": true,
    }, SetOptions(merge: true));
    await _refreshList();
    AppSnackbar("Sohbet Silindi", "Seçilen sohbet başarıyla silindi");
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
                title: model.isMuted ? "Sesi aç" : "Sessize al",
                icon: CupertinoIcons.bell_slash,
                onTap: () {
                  _toggleMuted();
                },
              ),
              PullDownMenuItem(
                title: "Arşivden çıkart",
                icon: CupertinoIcons.archivebox_fill,
                onTap: () {
                  _unarchiveChat();
                },
              ),
              PullDownMenuItem(
                title: "Sil",
                icon: CupertinoIcons.delete,
                isDestructive: true,
                onTap: () {
                  _deleteChat();
                },
              ),
            ]
          : [
              PullDownMenuItem(
                title: "Okunmadı olarak işaretle",
                icon: CupertinoIcons.mail,
                onTap: () {
                  _markUnread();
                },
              ),
              PullDownMenuItem(
                title: model.isPinned ? "Sabitten kaldır" : "Sabitle",
                icon: CupertinoIcons.pin,
                onTap: () {
                  _togglePinned();
                },
              ),
              PullDownMenuItem(
                title: model.isMuted ? "Sesi aç" : "Sessize al",
                icon: CupertinoIcons.bell_slash,
                onTap: () {
                  _toggleMuted();
                },
              ),
              PullDownMenuItem(
                title: "Arşivle",
                icon: CupertinoIcons.archivebox,
                onTap: () {
                  _archiveChat();
                },
              ),
              PullDownMenuItem(
                title: "Sil",
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
    controller = Get.put(
        ChatListingContentController(userID: model.userID, model: model),
        tag: model.userID);
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
                    child: model.pfImage != ""
                        ? CachedNetworkImage(
                            imageUrl: model.pfImage,
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
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt(
                        "chat_last_opened_${_uid}_${model.chatID}",
                        DateTime.now().millisecondsSinceEpoch,
                      );
                      controller.notReadCounter.value = 0;
                      model.unreadCount = 0;
                      await FirebaseFirestore.instance
                          .collection("conversations")
                          .doc(model.chatID)
                          .set({"unread.$_uid": 0}, SetOptions(merge: true));
                      await Get.to(() =>
                          ChatView(chatID: model.chatID, userID: model.userID));
                      if (Get.isRegistered<ChatListingController>()) {
                        await Get.find<ChatListingController>().getList();
                      }
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
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  "Sessiz",
                                  style: TextStyle(
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
