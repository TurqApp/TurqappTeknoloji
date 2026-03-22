part of 'profile_view.dart';

extension _ProfileViewShellPart on _ProfileViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenProfile),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.refreshAll(forceSync: true);
                      await _loadMarketItems(force: true);
                      socialMediaController.getData();
                    },
                    child: Obx(() => _buildProfileContent(context)),
                  ),
                ),
              ],
            ),
            Obx(
              () => controller.showScrollToTop.value
                  ? Positioned(
                      bottom: 90,
                      right: 20,
                      child: GestureDetector(
                        onTap: controller.animateCurrentSelectionToTop,
                        child: RoadToTop(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.showPfImage.value
                  ? _buildProfileImageOverlay()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return controller.postSelection.value == 0
        ? _buildPostsFeed()
        : controller.postSelection.value == 1
            ? buildVideoGrid()
            : controller.postSelection.value == 2
                ? buildPhotoGrid()
                : controller.postSelection.value == 3
                    ? buildReshares()
                    : controller.postSelection.value == 4
                        ? buildMarkets(context)
                        : controller.postSelection.value == 5
                            ? buildIzbiraklar(context)
                            : Column(children: [header()]);
  }

  Widget _buildPostsFeed() {
    final combinedPosts = controller.mergedPosts;

    if (combinedPosts.isEmpty) {
      return CustomScrollView(
        controller: controller.scrollControllerForSelection(0),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: header()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: EmptyRow(text: "profile.no_posts".tr)),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _scheduleOnScroll();
        return false;
      },
      child: ListView.builder(
        controller: controller.scrollControllerForSelection(0),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: combinedPosts.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return header();
          }

          if (index == combinedPosts.length + 1) {
            return 50.ph;
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
                    'profile-visibility-${controller.mergedEntryIdentity(docId: model.docID, isReshare: isReshare)}',
                  ),
                  onVisibilityChanged: (info) {
                    controller.onPostVisibilityChanged(
                      actualIndex,
                      info.visibleFraction,
                    );
                  },
                  child: Obx(() {
                    final isCentered =
                        controller.centeredIndex.value == actualIndex;
                    return Padding(
                      padding: EdgeInsets.only(top: actualIndex == 0 ? 12 : 0),
                      child: AgendaContent(
                        key: itemKey,
                        model: model,
                        isPreview: false,
                        shouldPlay: !controller.pausetheall.value &&
                            !controller.showPfImage.value &&
                            isCentered,
                        instanceTag: controller.agendaInstanceTag(
                          docId: model.docID,
                          isReshare: isReshare,
                        ),
                        isYenidenPaylasilanPost: isReshare,
                        reshareUserID: isReshare ? _myUserId : null,
                      ),
                    );
                  }),
                ),
                SizedBox(
                  height: 2,
                  child: Divider(color: Colors.grey.withAlpha(50)),
                ),
                if ((actualIndex + 1) % 4 == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AdmobKare(
                      key: ValueKey(
                        'myprof-ad-slot-${(actualIndex + 1) ~/ 4}',
                      ),
                    ),
                  ),
                if (combinedPosts.length < 4 &&
                    actualIndex == combinedPosts.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: AdmobKare(key: ValueKey('myprof-ad-end')),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImageOverlay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _hideProfileImagePreview,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              color: Colors.white.withValues(alpha: 0.2),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedUserAvatar(
                  userId: _myUserId,
                  imageUrl: _myAvatarUrl,
                  radius: 120,
                  placeholder: const DefaultAvatar(
                    radius: 120,
                    backgroundColor: Colors.transparent,
                    iconColor: Colors.white70,
                    padding: EdgeInsets.all(36),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
