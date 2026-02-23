import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_content.dart';
import 'package:turqappv2/Modules/RecommendedUserList/recommended_user_list_controller.dart';

import 'in_app_notifications_controller.dart';

class InAppNotifications extends StatelessWidget {
  InAppNotifications({super.key});
  final controller = Get.put(InAppNotificationsController());
  final recommendedController =
      Get.isRegistered<RecommendedUserListController>()
          ? Get.find<RecommendedUserListController>()
          : Get.put(RecommendedUserListController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabs(),

            // İçerik
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon:
                const Icon(CupertinoIcons.back, size: 24, color: Colors.black),
          ),
          const Expanded(
            child: Text(
              "Bildirimler",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontFamily: "MontserratBold",
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Obx(() {
              if (controller.list.isEmpty) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => _showNotificationActions(context),
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Obx(() {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(215),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _actionTile(
                          icon: Icons.mark_email_read_outlined,
                          title: controller.busyMarkAllRead.value
                              ? "Okundu işaretleniyor..."
                              : "Tümünü okundu yap",
                          enabled: controller.unreadCount > 0 &&
                              !controller.busyMarkAllRead.value,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            controller.markAllAsRead();
                          },
                        ),
                        Divider(height: 1, color: Colors.black.withAlpha(18)),
                        _actionTile(
                          icon: Icons.delete_outline,
                          title: "Tümünü Sil",
                          isDestructive: true,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            controller.list.clear();
                            controller.bildirimleriTopluSil();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
    bool isDestructive = false,
  }) {
    final textColor = !enabled
        ? Colors.black38
        : (isDestructive ? Colors.redAccent : Colors.black87);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return PageLineBar(
      barList: const [
        "Tümü",
        "Takip",
        "Yorum",
        "Bahsedenler",
      ],
      pageName: 'Notifications',
      fontSize: 15,
      pageController: controller.pageController,
    );
  }

  Widget _listForSelection(int index) {
    switch (index) {
      case 1:
        return _notificationList(
          _followNotifications(),
          emptyText: "Bu filtrede bildirim yok",
        );
      case 2:
        return _notificationList(
          _commentNotifications(),
          emptyText: "Bu filtrede bildirim yok",
        );
      case 3:
        return _notificationList(
          _mentionNotifications(),
          emptyText: "Bu filtrede bildirim yok",
        );
      case 0:
      default:
        return _notificationList(
          controller.list.toList(),
          emptyText: "Bu filtrede bildirim yok",
        );
    }
  }

  Widget _buildContent() {
    return Obx(() {
      if (!controller.complatedDataFetch.value) {
        return const Center(
          child: CupertinoActivityIndicator(color: Colors.grey),
        );
      }

      return PageView(
        controller: controller.pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (idx) {
          controller.selection.value = idx;
          Get.find<PageLineBarController>(tag: "Notifications")
              .selection
              .value = idx;
        },
        children: [
          _listForSelection(0),
          _listForSelection(1),
          _listForSelection(2),
          _listForSelection(3),
        ],
      );
    });
  }

  Widget _notificationList(List<dynamic> notifications,
      {required String emptyText}) {
    final children = <Widget>[const SizedBox(height: 6)];

    if (controller.list.isEmpty) {
      children.add(EmptyRow(text: "Bildiriminiz"));
    } else if (notifications.isEmpty) {
      children.add(EmptyRow(text: emptyText));
    } else {
      children.addAll(_buildGroupedList(notifications));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  List<dynamic> _mentionNotifications() {
    return controller.list.where(controller.isMentionNotification).toList();
  }

  List<dynamic> _followNotifications() {
    return controller.list.where((n) => n.postType == "User").toList();
  }

  List<dynamic> _commentNotifications() {
    return controller.list.where((n) => n.postType == "Comment").toList();
  }

  List<Widget> _buildGroupedList(List<dynamic> notifications) {
    final widgets = <Widget>[];
    final unread =
        notifications.where((n) => n.isRead == false).toList(growable: false);
    final read =
        notifications.where((n) => n.isRead == true).toList(growable: false);

    if (unread.isNotEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            "Yeni",
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
      );
      final unreadGroups = _groupByUser(unread);
      for (final g in unreadGroups) {
        final n = g.primary;
        final groupedCard = g.count > 1;
        final card = NotificationContent(
          model: _presentationModel(g),
          onOpen: () => controller.markManyAsRead(g.docIDs),
          onCardTap: groupedCard ? () => _openGroupSheet(g) : null,
        );
        widgets.add(
          Dismissible(
            key: ValueKey("unread_${n.docID}_${g.docIDs.length}"),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => controller.deleteMany(g.docIDs),
            child: groupedCard
                ? InkWell(
                    onTap: () {
                      controller.markManyAsRead(g.docIDs);
                      _openGroupSheet(g);
                    },
                    child: card,
                  )
                : card,
          ),
        );
      }
    }

    String? currentSection;
    final readGroups = _groupByUser(read);
    for (final g in readGroups) {
      final n = g.primary;
      final section = _sectionTitle(n.timeStamp.toInt());
      if (currentSection != section) {
        currentSection = section;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              section,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        );
      }

      widgets.add(
        Dismissible(
          key: ValueKey("read_${n.docID}_${g.docIDs.length}"),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => controller.deleteMany(g.docIDs),
          child: g.count > 1
              ? InkWell(
                  onTap: () {
                    controller.markManyAsRead(g.docIDs);
                    _openGroupSheet(g);
                  },
                  child: NotificationContent(
                    model: _presentationModel(g),
                    onOpen: () => controller.markManyAsRead(g.docIDs),
                    onCardTap: () => _openGroupSheet(g),
                  ),
                )
              : NotificationContent(
                  model: _presentationModel(g),
                  onOpen: () => controller.markManyAsRead(g.docIDs),
                ),
        ),
      );
    }
    return widgets;
  }

  List<_NotificationGroup> _groupByUser(List<dynamic> source) {
    final ordered = source.cast<NotificationModel>();
    final byUser = <String, _NotificationGroup>{};
    final order = <String>[];

    for (final n in ordered) {
      final userKey = n.userID.trim().isEmpty ? "unknown_${n.docID}" : n.userID;
      final existing = byUser[userKey];
      if (existing == null) {
        byUser[userKey] = _NotificationGroup(
          primary: n,
          docIDs: [n.docID],
          count: 1,
          items: [n],
        );
        order.add(userKey);
      } else {
        existing.docIDs.add(n.docID);
        existing.count += 1;
        existing.items.add(n);
      }
    }

    return order.map((k) => byUser[k]!).toList(growable: false);
  }

  NotificationModel _presentationModel(_NotificationGroup g) {
    if (g.count <= 1) return g.primary;
    final base = g.primary;
    final extra = g.count - 1;
    return NotificationModel(
      docID: base.docID,
      isRead: base.isRead,
      postID: base.postID,
      postType: base.postType,
      thumbnail: base.thumbnail,
      timeStamp: base.timeStamp,
      title: base.title,
      userID: base.userID,
      desc: "${base.desc} ve $extra bildirim daha",
    );
  }

  String _sectionTitle(int ts) {
    if (ts <= 0) return "Gündem";
    final now = DateTime.now();
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final startToday = DateTime(now.year, now.month, now.day);
    final startYesterday = startToday.subtract(const Duration(days: 1));

    if (d.isAfter(startToday)) return "Gündem";
    if (d.isAfter(startYesterday)) return "Dün";
    return "Daha eski";
  }

  void _openGroupSheet(_NotificationGroup g) {
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Bildirimler",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "MontserratBold",
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      "${g.count} adet",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  itemCount: g.items.length,
                  itemBuilder: (context, index) {
                    final item = g.items[index];
                    return NotificationContent(
                      model: item,
                      onOpen: () => controller.markAsRead(item.docID),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _NotificationGroup {
  final NotificationModel primary;
  final List<String> docIDs;
  final List<NotificationModel> items;
  int count;

  _NotificationGroup({
    required this.primary,
    required this.docIDs,
    required this.items,
    required this.count,
  });
}
