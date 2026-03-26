part of 'profile_view.dart';

extension _ProfileViewSocialPart on _ProfileViewState {
  Widget _buildLinksAndHighlightsRow() {
    final uid = _myUserId;
    if (uid.isEmpty) return const SizedBox.shrink();

    final tag = 'highlights_$uid';
    final hlController = _isProfileSurfaceActive()
        ? _ensureProfileHighlightsController()
        : StoryHighlightsController.maybeFind(tag: tag);

    return Obx(() {
      const rowHeight = 90.0;
      const itemWidth = 70.0;
      const itemSpacing = 18.0;
      final mixedItems = <Map<String, dynamic>>[];
      for (final model in socialMediaController.list) {
        mixedItems.add({
          'type': 'link',
          'id': model.docID,
          'data': model,
        });
      }
      if (hlController != null) {
        for (final hl in hlController.highlights) {
          mixedItems.add({
            'type': 'highlight',
            'id': hl.id,
            'data': hl,
          });
        }
      }
      if (mixedItems.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: SizedBox(
          height: rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: mixedItems.length,
            itemBuilder: (context, index) {
              final item = mixedItems[index];
              final isLastItem = index == mixedItems.length - 1;
              return Padding(
                key: ValueKey('${item['type']}:${item['id']}'),
                padding: EdgeInsets.only(right: isLastItem ? 0 : itemSpacing),
                child: _buildLinkHighlightTile(
                  context,
                  item,
                  uid,
                  hlController,
                  itemWidth,
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildLinkHighlightTile(
    BuildContext context,
    Map<String, dynamic> item,
    String uid,
    StoryHighlightsController? hlController,
    double width,
  ) {
    if (item['type'] == 'link') {
      final model = item['data'] as SocialMediaModel;
      return SizedBox(
        width: width,
        child: GestureDetector(
          onTap: () {
            confirmAndLaunchExternalUrl(Uri.parse(model.url));
          },
          onLongPress: () {
            controller.showSocialMediaLinkDelete(model.docID);
          },
          child: SocialMediaContent(model: model),
        ),
      );
    }

    final highlight = item['data'] as StoryHighlightModel;
    return SizedBox(
      width: width,
      child: StoryHighlightCircle(
        highlight: highlight,
        onTap: () => HighlightStoryViewerService.openHighlight(
          userId: uid,
          highlight: highlight,
        ),
        onLongPress: hlController == null
            ? null
            : () => _showHighlightDeleteConfirmation(hlController, highlight),
      ),
    );
  }

  Future<void> _showHighlightDeleteConfirmation(
    StoryHighlightsController hlController,
    StoryHighlightModel highlight,
  ) async {
    await noYesAlert(
      title: "profile.highlight_remove_title".tr,
      message: "profile.highlight_remove_body".tr,
      cancelText: "common.cancel".tr,
      yesText: "common.remove".tr,
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () async {
        await hlController.deleteHighlight(highlight.id);
      },
    );
  }

  Widget _buildProfileImageWithBorder() {
    if (_hasMyStories) {
      return Container(
        width: 91,
        height: 91,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00BCD4),
              Color(0xFF0097A7),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: CachedUserAvatar(
            userId: _myUserId,
            imageUrl: _myAvatarUrl,
            radius: 42.5,
          ),
        ),
      );
    }

    return CachedUserAvatar(
      userId: _myUserId,
      imageUrl: _myAvatarUrl,
      radius: 42.5,
    );
  }
}
