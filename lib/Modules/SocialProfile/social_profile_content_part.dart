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
                onRefresh: controller.refreshAll,
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
    if (controller.isPrivateContentBlockedFor(_myUserId)) {
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
          final isCentered = controller.centeredIndex.value == actualIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              children: [
                AgendaContent(
                  key: itemKey,
                  model: model,
                  isPreview: false,
                  shouldPlay: !controller.showPfImage.value && isCentered,
                  instanceTag: controller.agendaInstanceTag(
                    docId: model.docID,
                    isReshare: isReshare,
                  ),
                  isYenidenPaylasilanPost: isReshare,
                  reshareUserID: isReshare ? controller.userID : null,
                ),
                SizedBox(
                  height: 2,
                  child: Divider(color: Colors.grey.withAlpha(50)),
                ),
                if ((actualIndex + 1) % 4 == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AdmobKare(
                      key: ValueKey(
                        'socialprof-ad-slot-${(actualIndex + 1) ~/ 4}',
                      ),
                    ),
                  ),
                if (combinedPosts.isNotEmpty &&
                    combinedPosts.length < 4 &&
                    actualIndex == combinedPosts.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: AdmobKare(key: ValueKey('socialprof-ad-end')),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
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
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 100,
        color: Colors.grey[600],
      ),
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

  Widget buildReshares() {
    final hasVideos = controller.reshares.isNotEmpty;

    return CustomScrollView(
      controller: _scrollControllerForSelection(3),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (hasVideos)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = controller.reshares[index];
              return GestureDetector(
                onTap: () async {
                  _suspendCenteredPostForRoute(model);
                  if (model.hasPlayableVideo) {
                    await Get.to(
                      () => SingleShortView(
                        startList: controller.reshares
                            .where((val) => val.hasPlayableVideo)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  } else {
                    await Get.to(
                      () => PhotoShorts(
                        fetchedList: controller.reshares
                            .where((val) => val.img.isNotEmpty)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  }
                  _resumeCenteredPostAfterRoute();
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail != ''
                            ? model.thumbnail
                            : model.img.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    if (model.hasPlayableVideo)
                      const Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    if (!model.hasPlayableVideo && model.img.isNotEmpty)
                      const Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.photo,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/statsyeni.svg',
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 3),
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: controller.reshares.length),
          )
        else
          SliverToBoxAdapter(
            child: Center(child: EmptyRow(text: 'profile.no_reshares'.tr)),
          ),
      ],
    );
  }

  Widget buildPhotoGrid() {
    final visiblePosts = controller.photos;
    final childCount =
        visiblePosts.length + (controller.isLoadingPhoto.value ? 1 : 0);

    if (visiblePosts.isEmpty) {
      return Column(
        children: [
          header(),
          Center(child: EmptyRow(text: 'profile.no_photos'.tr)),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollControllerForSelection(2),
      slivers: [
        SliverToBoxAdapter(child: header()),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 0.5,
            crossAxisSpacing: 0.5,
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == visiblePosts.length &&
                  controller.isLoadingPhoto.value) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final model = visiblePosts[index];
              return GestureDetector(
                onTap: () async {
                  _suspendCenteredPostForRoute(model);
                  if (model.floodCount > 1) {
                    await Get.to(() => FloodListing(mainModel: model));
                  } else {
                    await Get.to(
                      () => PhotoShorts(
                        fetchedList: visiblePosts,
                        startModel: model,
                      ),
                    );
                  }
                  _resumeCenteredPostAfterRoute();
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.img.first,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                      ),
                    ),
                    if (model.img.length > 1)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.photo_on_rectangle,
                          color: Colors.white,
                          size: 20,
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/statsyeni.svg',
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 3),
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: childCount,
          ),
        ),
      ],
    );
  }

  Widget buildVideoGrid() {
    final visibleVideos =
        controller.allPosts.where((post) => post.hasPlayableVideo).toList();
    final childCount =
        visibleVideos.length + (controller.isLoadingPosts.value ? 1 : 0);

    if (visibleVideos.isEmpty) {
      return Column(
        children: [
          header(),
          Center(child: EmptyRow(text: 'profile.no_videos'.tr)),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollControllerForSelection(1),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: header()),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 0.6,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == visibleVideos.length &&
                  controller.isLoadingPosts.value) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final model = visibleVideos[index];
              return GestureDetector(
                onTap: () async {
                  _suspendCenteredPostForRoute(model);
                  if (model.floodCount > 1) {
                    await Get.to(() => FloodListing(mainModel: model));
                  } else {
                    await Get.to(
                      () => SingleShortView(
                        startList: visibleVideos,
                        startModel: model,
                      ),
                    );
                  }
                  _resumeCenteredPostAfterRoute();
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 4,
                      right: 4,
                      child: Icon(
                        CupertinoIcons.play_circle_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/statsyeni.svg',
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 3),
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: childCount,
          ),
        ),
      ],
    );
  }

  Widget buildIzbiraklar(BuildContext context) {
    return CustomScrollView(
      controller: _scrollControllerForSelection(5),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (controller.scheduledPosts.isNotEmpty)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = controller.scheduledPosts[index];
              final hedef = DateTime.fromMillisecondsSinceEpoch(
                model.izBirakYayinTarihi.toInt(),
              );
              final kalanText = kacGunKaldiFormatter(hedef);
              final isPublished = DateTime.now().millisecondsSinceEpoch >=
                  hedef.millisecondsSinceEpoch;

              return Stack(
                children: [
                  SizedBox.expand(
                    child: CachedNetworkImage(
                      imageUrl: model.thumbnail.isNotEmpty
                          ? model.thumbnail
                          : (model.img.isNotEmpty ? model.img.first : ''),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CupertinoActivityIndicator(color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: CupertinoActivityIndicator(color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      model.hasPlayableVideo
                          ? CupertinoIcons.play_circle_fill
                          : CupertinoIcons.photo,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (!isPublished)
                    Positioned.fill(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                  if (!isPublished)
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.62),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                kalanText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'MontserratBold',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await IzBirakSubscriptionService.ensure()
                                  .subscribe(model.docID);
                              AppSnackbar(
                                'profile.scheduled_subscribe_title'.tr,
                                'profile.scheduled_subscribe_body'.tr,
                              );
                            },
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.add,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }, childCount: controller.scheduledPosts.length),
          )
        else
          SliverToBoxAdapter(
            child: Center(child: EmptyRow(text: 'profile.scheduled_none'.tr)),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }
}
