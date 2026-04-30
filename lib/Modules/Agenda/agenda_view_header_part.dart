part of 'agenda_view.dart';

extension _AgendaViewHeaderPart on AgendaView {
  Widget header() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final horizontalPadding = compact ? 12.0 : 15.0;
        const trailingGap = 6.0;
        const actionSize = 36.0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: 15,
                top: Get.mediaQuery.padding.top + 3,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildFeedTitleSelector(compact: compact),
                  ),
                  SizedBox(width: compact ? 4 : 8),
                  _buildViewToggle(actionSize: actionSize),
                  SizedBox(width: trailingGap),
                  _DeferredNotificationInboxActions(
                    actionSize: actionSize,
                    trailingGap: trailingGap,
                    agendaController: controller,
                  ),
                ],
              ),
            ),
            StoryRow(),
            5.ph,
          ],
        );
      },
    );
  }

  Widget _buildFeedTitleSelector({required bool compact}) {
    return Obx(() {
      final title = controller.feedTitle;
      final isDefaultTitle = !controller.isFollowingMode;
      final fontSize = isDefaultTitle
          ? (compact ? 28.0 : (GetPlatform.isAndroid ? 31.0 : 27.0))
          : (compact ? 21.0 : (GetPlatform.isAndroid ? 24.0 : 21.0));

      return PopupMenuButton<FeedViewMode>(
        tooltip: '',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        color: Colors.white,
        elevation: 10,
        offset: const Offset(0, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onSelected: controller.setFeedViewMode,
        itemBuilder: (context) => [
          PopupMenuItem<FeedViewMode>(
            value: FeedViewMode.forYou,
            child: Row(
              children: [
                const Icon(CupertinoIcons.sparkles, size: 18),
                const SizedBox(width: 8),
                Text(
                  'explore.tab.for_you'.tr,
                  style: const TextStyle(
                    fontFamily: AppFontFamilies.mmedium,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<FeedViewMode>(
            value: FeedViewMode.following,
            child: Row(
              children: [
                const Icon(CupertinoIcons.person_2, size: 18),
                const SizedBox(width: 8),
                Text(
                  'agenda.following'.tr,
                  style: const TextStyle(
                    fontFamily: AppFontFamilies.mmedium,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<FeedViewMode>(
            value: FeedViewMode.city,
            child: Row(
              children: [
                const Icon(CupertinoIcons.location_solid, size: 18),
                const SizedBox(width: 8),
                Text(
                  'agenda.city'.tr,
                  style: const TextStyle(
                    fontFamily: AppFontFamilies.mmedium,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.secondColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    title,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: AppFontFamilies.mbold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.secondColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildViewToggle({required double actionSize}) {
    return Obx(() {
      final userService = CurrentUserService.instance;
      final currentSelection = userService.viewSelectionRx.value;

      return AppHeaderActionButton(
        size: actionSize,
        onTap: () async {
          final nextSelection = currentSelection == 1 ? 0 : 1;
          await userService.updateFields({
            "viewSelection": nextSelection,
          });
        },
        child: const Icon(
          CupertinoIcons.rectangle_grid_1x2,
          color: Colors.black,
          size: AppIconSurface.kIconSize,
        ),
      );
    });
  }

  Widget _feedLoadingSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: MediaQuery.of(context).size.width * 0.62,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 360,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeferredNotificationInboxActions extends StatefulWidget {
  const _DeferredNotificationInboxActions({
    required this.actionSize,
    required this.trailingGap,
    required this.agendaController,
  });

  final double actionSize;
  final double trailingGap;
  final AgendaController agendaController;

  @override
  State<_DeferredNotificationInboxActions> createState() =>
      _DeferredNotificationInboxActionsState();
}

class _DeferredNotificationInboxActionsState
    extends State<_DeferredNotificationInboxActions> {
  InAppNotificationsController? _notificationsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindNotificationsControllerWhenFeedReady();
    });
  }

  void _bindNotificationsControllerWhenFeedReady() {
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || _notificationsController != null) return;
      final prefetch = maybeFindPrefetchScheduler();
      final readyThreshold = ReadBudgetRegistry.feedReadyForNavCount > 10
          ? ReadBudgetRegistry.feedReadyForNavCount
          : 10;
      final feedReadyEnough =
          prefetch == null || prefetch.feedReadyCount >= readyThreshold;
      if (widget.agendaController.renderFeedEntries.isEmpty ||
          widget.agendaController.centeredIndex.value < 0 ||
          !feedReadyEnough) {
        _bindNotificationsControllerWhenFeedReady();
        return;
      }
      setState(() {
        _notificationsController = InAppNotificationsController.ensure();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadController = ensureUnreadMessagesController();
    return Obx(() {
      final hasChatUnread = unreadController.totalUnreadCount.value > 0;
      final hasNotificationUnread =
          (_notificationsController?.unreadCount ?? 0) > 0;
      return FeedInboxActionsRow(
        actionSize: widget.actionSize,
        spacing: widget.trailingGap,
        showChatBadge: hasChatUnread,
        showNotificationBadge: hasNotificationUnread,
        onChatTap: () async {
          final notificationsController =
              _notificationsController ?? InAppNotificationsController.ensure();
          final unreadChatIds = notificationsController.list
              .where(
                  (n) => n.postType == kNotificationPostTypeChat && !n.isRead)
              .map((n) => n.docID)
              .toList(growable: false);
          if (unreadChatIds.isNotEmpty) {
            await notificationsController.markManyAsRead(unreadChatIds);
          }
          final prevIndex = widget.agendaController.lastCenteredIndex;
          widget.agendaController.lastCenteredIndex = prevIndex;
          widget.agendaController.suspendPlaybackForOverlay();
          const ChatNavigationService().openChatListing().then((_) {
            widget.agendaController.resumePlaybackAfterOverlay();
            try {
              unawaited(
                ensureRecommendedUserListController().ensureLoaded(),
              );
            } catch (_) {}
          });
        },
        onNotificationsTap: () {
          _notificationsController ??= InAppNotificationsController.ensure();
          final prevIndex = widget.agendaController.lastCenteredIndex;
          widget.agendaController.lastCenteredIndex = prevIndex;
          widget.agendaController.suspendPlaybackForOverlay();
          Get.to(() => InAppNotifications())?.then((_) {
            widget.agendaController.resumePlaybackAfterOverlay();
            try {
              unawaited(
                ensureRecommendedUserListController().ensureLoaded(),
              );
            } catch (_) {}
          });
        },
      );
    });
  }
}
