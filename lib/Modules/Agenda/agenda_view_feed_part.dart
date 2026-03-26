part of 'agenda_view.dart';

extension _AgendaViewFeedPart on AgendaView {
  Widget _buildRefreshableFeed(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: Colors.black,
      color: Colors.white,
      onRefresh: () async {
        await resetPlaybackForSurfaceRefresh();
        await controller.refreshAgenda();
        try {
          await unreadController.refreshUnreadCount();
        } catch (e) {
          print("Unread messages refresh error: $e");
        }
        try {
          await StoryRowController.maybeFind()?.loadStories();
        } catch (e) {
          print("Story refresh error: $e");
        }
        try {
          await recommendedController.getUsers();
        } catch (_) {}
      },
      child: Obx(() {
        final display = controller.mergedFeedEntries;
        final filteredDisplay = controller.filteredFeedEntries;
        final renderDisplay = controller.renderFeedEntries;
        final displayCount = display.length;
        final filteredCount = filteredDisplay.length;

        if (displayCount == 0) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                header(),
                const SizedBox(height: 18),
                _feedLoadingSkeleton(context),
                _feedLoadingSkeleton(context),
                _feedLoadingSkeleton(context),
                const SizedBox(height: 70),
              ],
            ),
          );
        }

        if (filteredCount == 0) {
          final emptyText = controller.isCityMode
              ? 'feed.empty_city'.tr
              : 'feed.empty_following'.tr;
          return _buildEmptyFeedState(emptyText);
        }

        return ListView.builder(
          controller: controller.scrollController,
          physics: GetPlatform.isAndroid
              ? const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : const AlwaysScrollableScrollPhysics(),
          cacheExtent: GetPlatform.isIOS ? 180.0 : 220.0,
          padding: const EdgeInsets.only(
            bottom: kBottomNavigationBarHeight + 16,
          ),
          itemCount: renderDisplay.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return header();

            final actualIndex = index - 1;
            if (actualIndex >= renderDisplay.length) {
              return const SizedBox.shrink();
            }

            return _buildFeedItem(renderDisplay[actualIndex]);
          },
        );
      }),
    );
  }

  Widget _buildEmptyFeedState(String emptyText) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          header(),
          const SizedBox(height: 32),
          const Icon(
            CupertinoIcons.person_2_fill,
            color: Colors.black26,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            emptyText,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontFamily: AppFontFamilies.mmedium,
            ),
          ),
          const SizedBox(height: 220),
        ],
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item) {
    final renderType = (item['renderType'] ?? 'post').toString();
    if (renderType == 'promo') {
      return RepaintBoundary(
        child: Padding(
          key: ValueKey('promo-${item['promoType']}-${item['slotNumber']}'),
          padding: const EdgeInsets.only(bottom: 0),
          child: _buildPromoSlot(item),
        ),
      );
    }

    final model = item['model'] as PostsModel;
    final isReshare = item['reshare'] == true;
    final reshareUserID = item['reshareUserID'] as String?;
    final agendaIndex = (item['agendaIndex'] ?? -1) as int;
    final stableKeyString = isReshare
        ? '${model.docID}_reshare_$reshareUserID'
        : '${model.docID}_original';

    final basePostWidget = VisibilityDetector(
      key: Key('visibility_$stableKeyString'),
      onVisibilityChanged: (info) {
        if (model.hasPlayableVideo) return;
        if (agendaIndex < 0) return;
        controller.onPostVisibilityChanged(
          agendaIndex,
          info.visibleFraction,
        );
      },
      child: _buildPostContent(
        model: model,
        stableKeyString: stableKeyString,
        isReshare: isReshare,
        reshareUserID: reshareUserID,
        agendaIndex: agendaIndex,
      ),
    );

    final postWidget = Obx(() {
      final isHighlighted = controller.highlightDocIDs.contains(model.docID);
      if (!isHighlighted) {
        return basePostWidget;
      }

      return TweenAnimationBuilder<double>(
        key: ValueKey('hl-${model.docID}'),
        tween: Tween(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          final dy = -12.0 * t;
          return Stack(
            children: [
              Transform.translate(
                offset: Offset(0, dy),
                child: child!,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.textBlue.withValues(alpha: 0.10 * t),
                          AppColors.textPink.withValues(alpha: 0.10 * t),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: basePostWidget,
      );
    });

    return RepaintBoundary(
      child: Padding(
        key: ValueKey('row-$stableKeyString'),
        padding: const EdgeInsets.only(bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            postWidget,
            Divider(
              color: Colors.grey.withAlpha(20),
              height: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent({
    required PostsModel model,
    required String stableKeyString,
    required bool isReshare,
    required String? reshareUserID,
    required int agendaIndex,
  }) {
    if (!model.hasPlayableVideo) {
      return Obx(() {
        final viewSelection =
            CurrentUserService.instance.effectiveViewSelection;
        if (viewSelection == 1) {
          return AgendaContent(
            key: ValueKey(stableKeyString),
            model: model,
            isPreview: false,
            shouldPlay: false,
            isYenidenPaylasilanPost: isReshare,
            reshareUserID: reshareUserID,
          );
        }
        return ClassicContent(
          key: ValueKey(stableKeyString),
          model: model,
          isPreview: false,
          shouldPlay: false,
          isYenidenPaylasilanPost: isReshare,
          reshareUserID: reshareUserID,
        );
      });
    }

    return GetBuilder<AgendaController>(
      id: controller.feedPlaybackRowUpdateId(agendaIndex),
      builder: (agendaController) {
        final isCentered = agendaController.centeredIndex.value == agendaIndex;
        return Obx(() {
          final viewSelection =
              CurrentUserService.instance.effectiveViewSelection;
          if (viewSelection == 1) {
            return AgendaContent(
              key: ValueKey(stableKeyString),
              model: model,
              isPreview: false,
              shouldPlay: isCentered,
              isYenidenPaylasilanPost: isReshare,
              reshareUserID: reshareUserID,
            );
          }
          return ClassicContent(
            key: ValueKey(stableKeyString),
            model: model,
            isPreview: false,
            shouldPlay: isCentered,
            isYenidenPaylasilanPost: isReshare,
            reshareUserID: reshareUserID,
          );
        });
      },
    );
  }

  Widget _buildPromoSlot(Map<String, dynamic> entry) {
    final promoType = (entry['promoType'] ?? '').toString();
    final slotNumber = (entry['slotNumber'] ?? 0) as int;
    final isModernView = CurrentUserService.instance.effectiveViewSelection == 1;
    final isAndroidClassic = GetPlatform.isAndroid && !isModernView;
    final liveAdOffsetX = isModernView
        ? 5.0
        : isAndroidClassic
            ? 0.0
            : -32.0;
    final edgeInsets = isModernView
        ? const EdgeInsets.fromLTRB(48, 8, 5, 8)
        : const EdgeInsets.fromLTRB(48, 8, 5, 8);
    if (promoType == 'ad') {
      return Padding(
        padding: edgeInsets,
        child: AdmobKare(
          key: ValueKey('agenda-feed-ad-$slotNumber'),
          contentPadding: EdgeInsets.zero,
          liveAdOffsetX: liveAdOffsetX,
          promoFallbackOffsetX: isModernView ? 0 : -20.0,
          promoFallbackExtraWidth: 0,
          forceSingleLinePromoChips: true,
        ),
      );
    }
    final recommendedBatch = (entry['recommendedBatch'] ?? 0) as int;
    return Padding(
      padding: isModernView
          ? const EdgeInsets.fromLTRB(5, 2, 5, 10)
          : const EdgeInsets.only(top: 2, bottom: 10),
      child: RecommendedUserList(
        key: ValueKey('recommendedUserList-$recommendedBatch'),
        batch: recommendedBatch,
      ),
    );
  }

  Widget _buildCreateFab() {
    return Obx(() {
      if (!controller.showFAB.value) {
        return const SizedBox.shrink();
      }
      return Positioned(
        bottom: 82,
        right: 20,
        child: FeedCreateFab(
          onTap: () {
            final prevIndex = controller.lastCenteredIndex;
            controller.lastCenteredIndex = prevIndex;
            controller.suspendPlaybackForOverlay();
            Get.to(() => PostCreator())?.then((_) {
              controller.resumePlaybackAfterOverlay();
            });
          },
        ),
      );
    });
  }
}
