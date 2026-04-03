part of 'in_app_notifications.dart';

extension InAppNotificationsShellContentPart on _InAppNotificationsState {
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
          Expanded(
            child: Text(
              'notifications.title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontFamily: 'MontserratBold',
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
                  key: const ValueKey(
                    IntegrationTestKeys.actionNotificationsMore,
                  ),
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
    try {
      maybeFindNavBarController()?.pushMediaOverlayLock();
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return SafeArea(
            top: false,
            child: Obx(() {
              return NotificationActionsSheetContent(
                unreadCount: controller.unreadCount,
                busyMarkAllRead: controller.busyMarkAllRead.value,
                onMarkAllRead: () {
                  Navigator.of(ctx).pop();
                  controller.markAllAsRead();
                },
                onDeleteAll: () {
                  Navigator.of(ctx).pop();
                  controller.list.clear();
                  controller.bildirimleriTopluSil();
                },
              );
            }),
          );
        },
      );
    } finally {
      try {
        maybeFindNavBarController()?.popMediaOverlayLock();
      } catch (_) {}
    }
  }

  Widget _buildTabs() {
    return PageLineBar(
      barList: [
        'common.all'.tr,
        'notifications.tab_follow'.tr,
        'notifications.tab_comment'.tr,
        'notifications.tab_mentions'.tr,
        'notifications.tab_listings'.tr,
      ],
      pageName: _pageLineBarTag,
      fontSize: 15,
      pageController: controller.pageController,
    );
  }

  Widget _listForSelection(int index) {
    switch (index) {
      case 1:
        return _notificationList(
          _followNotifications(),
          emptyText: 'notifications.empty_filtered'.tr,
        );
      case 2:
        return _notificationList(
          _commentNotifications(),
          emptyText: 'notifications.empty_filtered'.tr,
        );
      case 3:
        return _notificationList(
          _mentionNotifications(),
          emptyText: 'notifications.empty_filtered'.tr,
        );
      case 4:
        return _notificationList(
          _listingNotifications(),
          emptyText: 'notifications.empty_filtered'.tr,
        );
      case 0:
      default:
        return _notificationList(
          controller.list.toList(),
          emptyText: 'notifications.empty_filtered'.tr,
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
          syncPageLineBarSelection(_pageLineBarTag, idx);
        },
        children: [
          _listForSelection(0),
          _listForSelection(1),
          _listForSelection(2),
          _listForSelection(3),
          _listForSelection(4),
        ],
      );
    });
  }
}
