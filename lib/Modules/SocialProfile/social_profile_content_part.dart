part of 'social_profile.dart';

extension _SocialProfileContentPart on _SocialProfileState {
  Widget _buildSocialProfileScaffold(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenSocialProfile),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Stack(
            children: [
              RefreshIndicator(
                backgroundColor: Colors.black,
                color: Colors.white,
                onRefresh: () => runSurfaceRefresh(
                  primaryRefresh: controller.refreshAll,
                ),
                child: Column(
                  children: [
                    if (!controller.isBlockedByCurrentViewer(widget.userID))
                      Expanded(child: _buildProfileBody(context))
                    else
                      _buildBlockedState(),
                  ],
                ),
              ),
              if (controller.showPfImage.value) _buildProfileImageOverlay(),
              if (controller.showScrollToTop.value) _buildScrollToTopButton(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfileBody(BuildContext context) {
    final isPrivateBlocked = controller.isPrivateContentBlockedFor(_myUserId);
    if (isPrivateBlocked) {
      debugPrint(
        '[SocialProfileGate] state=private_blocked userId=${widget.userID} '
        'viewer=$_myUserId isPrivate=${controller.gizliHesap.value} following=${controller.takipEdiyorum.value}',
      );
      return _buildPrivateState();
    }

    switch (controller.postSelection.value) {
      case 0:
        return _buildFeedList();
      case 1:
        return buildVideoGrid();
      case 2:
        return buildPhotoGrid();
      case 3:
        return buildReshares();
      case 4:
        return buildMarkets(context);
      case 5:
        return buildIzbiraklar(context);
      default:
        return Column(children: [header()]);
    }
  }

  Widget _buildPrivateState() {
    return Column(
      children: [
        header(),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.lock_fill,
                  color: Colors.pinkAccent,
                  size: 35,
                ),
                const SizedBox(height: 12),
                Text(
                  'profile.private_account_title'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'social_profile.private_follow_to_see_posts'.tr,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlockedState() {
    return Column(
      children: [
        header(),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.xmark_shield,
                  color: Colors.pinkAccent,
                  size: 35,
                ),
                const SizedBox(height: 12),
                Text(
                  'social_profile.blocked_user'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedList() {
    final combinedPosts = controller.combinedFeedEntries;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _scheduleOnScroll();
        return false;
      },
      child: ListView.builder(
        controller: _scrollControllerForSelection(0),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: combinedPosts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  header(),
                  if (combinedPosts.isEmpty)
                    EmptyRow(text: 'common.no_results'.tr),
                ],
              ),
            );
          }

          final actualIndex = index - 1;
          final item = combinedPosts[actualIndex];
          final model = item['post'] as PostsModel;
          final isReshare = item['isReshare'] as bool;
          final itemKey = controller.getPostKey(
            docId: model.docID,
            isReshare: isReshare,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              children: [
                VisibilityDetector(
                  key: Key(
                    'social-profile-visibility-${controller.combinedEntryIdentity(docId: model.docID, isReshare: isReshare)}',
                  ),
                  onVisibilityChanged: (info) {
                    controller.onPostVisibilityChanged(
                      actualIndex,
                      info.visibleFraction,
                    );
                  },
                  child: GetBuilder<SocialProfileController>(
                    tag: controller.userID,
                    id: controller.feedPlaybackRowUpdateId(
                      docId: model.docID,
                      isReshare: isReshare,
                    ),
                    builder: (socialController) {
                      final isCentered =
                          socialController.centeredIndex.value == actualIndex;
                      final shouldPlay =
                          FeedPlaybackSelectionPolicy.shouldPlayCenteredItem(
                        isCentered: isCentered,
                        isSurfacePlaybackSuspended:
                            socialController.surfacePlaybackSuspended.value,
                        isOverlayBlockingPlayback:
                            socialController.showPfImage.value,
                      );
                      return AgendaContent(
                        key: itemKey,
                        model: model,
                        isPreview: false,
                        shouldPlay: shouldPlay,
                        instanceTag: socialController.agendaInstanceTag(
                          docId: model.docID,
                          isReshare: isReshare,
                        ),
                        isYenidenPaylasilanPost: isReshare,
                        reshareUserID:
                            isReshare ? socialController.userID : null,
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 2,
                  child: Divider(color: Colors.grey.withAlpha(50)),
                ),
                if ((actualIndex + 1) % 4 == 0)
                  _buildFeedMirroredPromoSlot(
                    slotNumber: (actualIndex + 1) ~/ 4,
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedMirroredPromoSlot({
    required int slotNumber,
  }) {
    final isModernView =
        CurrentUserService.instance.effectiveViewSelection == 1;
    final liveAdOffsetX = isModernView ? 5.0 : 5.0;
    final edgeInsets = isModernView
        ? const EdgeInsets.fromLTRB(48, 8, 5, 8)
        : const EdgeInsets.fromLTRB(5, 8, 5, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: edgeInsets,
          child: AdmobKare(
            key: ValueKey('socialprof-feed-ad-$slotNumber'),
            contentPadding: EdgeInsets.zero,
            liveAdOffsetX: liveAdOffsetX,
            promoFallbackOffsetX: 0,
            promoFallbackExtraWidth: 0,
            forceSingleLinePromoChips: true,
            suggestionPlacementId: 'feed',
          ),
        ),
        if (!isModernView) ...[
          const SizedBox(height: 7),
          Divider(
            color: Colors.grey.withAlpha(20),
            height: 3,
          ),
          const SizedBox(height: 13),
        ],
      ],
    );
  }

  Widget _buildProfileImageOverlay() {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: _hideProfileImagePreview,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(
                child: controller.avatarUrl.value.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: controller.avatarUrl.value,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        memCacheHeight: 600,
                        placeholder: (context, url) => _buildAvatarFallback(),
                        errorWidget: (context, url, error) =>
                            _buildAvatarFallback(),
                      )
                    : _buildAvatarFallback(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return SvgPicture.asset(
      kDefaultAvatarAsset,
      fit: BoxFit.cover,
    );
  }

  Widget _buildScrollToTopButton() {
    return Positioned(
      right: 15,
      bottom: 20,
      child: GestureDetector(
        onTap: () {
          final scrollController = _currentScrollController;
          if (!scrollController.hasClients) return;
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        },
        child: const RoadToTop(),
      ),
    );
  }
}
