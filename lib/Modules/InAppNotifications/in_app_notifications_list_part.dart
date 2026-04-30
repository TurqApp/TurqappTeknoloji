part of 'in_app_notifications.dart';

extension InAppNotificationsListPart on _InAppNotificationsState {
  Widget _notificationList(
    List<NotificationModel> notifications, {
    required String emptyText,
  }) {
    final children = <Widget>[const SizedBox(height: 6)];

    if (controller.list.isEmpty) {
      children.add(AppStateView.empty(title: 'notifications.empty'.tr));
    } else if (notifications.isEmpty) {
      children.add(AppStateView.empty(title: emptyText));
    } else {
      children.addAll(_buildGroupedList(notifications));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  List<NotificationModel> _mentionNotifications() {
    return controller.list.where(controller.isMentionNotification).toList();
  }

  List<NotificationModel> _followNotifications() {
    return controller.list
        .where((n) => n.postType == kNotificationPostTypeUser)
        .toList();
  }

  List<NotificationModel> _commentNotifications() {
    return controller.list
        .where((n) => n.postType == kNotificationPostTypeComment)
        .toList();
  }

  List<NotificationModel> _listingNotifications() {
    return controller.list.where(_isListingNotification).toList();
  }

  bool _isListingNotification(NotificationModel notification) {
    final normalizedType = normalizeNotificationType(notification.type, '');
    final normalizedPostType =
        normalizeNotificationType('', notification.postType);

    return isListingNotificationType(normalizedType) ||
        isListingNotificationPostType(normalizedPostType);
  }

  List<Widget> _buildGroupedList(List<NotificationModel> notifications) {
    final widgets = <Widget>[];
    final unread =
        notifications.where((n) => n.isRead == false).toList(growable: false);
    final read =
        notifications.where((n) => n.isRead == true).toList(growable: false);

    if (unread.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            'notifications.new'.tr,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontFamily: 'MontserratBold',
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
            key: ValueKey('unread_${n.docID}_${g.docIDs.length}'),
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
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
        );
      }

      widgets.add(
        Dismissible(
          key: ValueKey('read_${n.docID}_${g.docIDs.length}'),
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

  List<_NotificationGroup> _groupByUser(List<NotificationModel> source) {
    final byUser = <String, _NotificationGroup>{};
    final order = <String>[];

    for (final n in source) {
      final userKey = n.userID.trim().isEmpty ? 'unknown_${n.docID}' : n.userID;
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
      type: base.type,
      postID: base.postID,
      postType: base.postType,
      thumbnail: base.thumbnail,
      timeStamp: base.timeStamp,
      title: base.title,
      userID: base.userID,
      desc: 'notifications.and_more'.trParams({
        'base': base.desc,
        'count': '$extra',
      }),
    );
  }

  String _sectionTitle(int ts) {
    if (ts <= 0) return 'notifications.today'.tr;
    final now = DateTime.now();
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final startToday = DateTime(now.year, now.month, now.day);
    final startYesterday = startToday.subtract(const Duration(days: 1));

    if (d.isAfter(startToday)) return 'notifications.today'.tr;
    if (d.isAfter(startYesterday)) return 'notifications.yesterday'.tr;
    return 'notifications.older'.tr;
  }

  void _openGroupSheet(_NotificationGroup g) {
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.78),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: AppSheetHeader(title: 'notifications.title'.tr),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'notifications.count_items'.trParams({'count': '${g.count}'}),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontFamily: 'MontserratMedium',
                  ),
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
