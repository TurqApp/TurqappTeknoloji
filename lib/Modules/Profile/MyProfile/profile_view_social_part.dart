part of 'profile_view.dart';

extension _ProfileViewSocialPart on _ProfileViewState {
  Widget _buildLinkHighlightTile(
    BuildContext context,
    Map<String, dynamic> item,
    String uid,
    StoryHighlightsController hlController,
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
        onLongPress: () =>
            _showHighlightDeleteConfirmation(hlController, highlight),
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
