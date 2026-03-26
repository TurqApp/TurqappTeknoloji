part of 'social_profile.dart';

extension _SocialProfileSectionsPart on _SocialProfileState {
  Widget _buildLinksAndHighlightsRow() {
    final tag = 'highlights_${widget.userID}';
    final hlController = maybeFindStoryHighlightsController(tag: tag);
    if (hlController == null) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      const itemSpacing = 10.0;
      final mixedItems = <Map<String, dynamic>>[];
      for (final social in controller.socialMediaList) {
        mixedItems.add({
          'type': 'link',
          'createdAt': int.tryParse(social.docID) ?? 0,
          'data': social,
        });
      }
      for (final hl in hlController.highlights) {
        mixedItems.add({
          'type': 'highlight',
          'createdAt': hl.createdAt.millisecondsSinceEpoch,
          'data': hl,
        });
      }
      if (mixedItems.isEmpty) return const SizedBox.shrink();
      mixedItems.sort(
          (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      return Padding(
        padding: const EdgeInsets.only(top: 7, bottom: 4),
        child: SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 15),
            itemCount: mixedItems.length,
            itemBuilder: (context, index) {
              final item = mixedItems[index];
              final isLastItem = index == mixedItems.length - 1;
              if (item['type'] == 'link') {
                final social = item['data'] as SocialMediaModel;
                return Padding(
                  padding: EdgeInsets.only(right: isLastItem ? 0 : itemSpacing),
                  child: SizedBox(
                    width: 70,
                    child: GestureDetector(
                      onTap: () {
                        confirmAndLaunchExternalUrl(Uri.parse(social.url));
                      },
                      child: SocialMediaContent(model: social),
                    ),
                  ),
                );
              }
              final hl = item['data'] as StoryHighlightModel;
              return Padding(
                padding: EdgeInsets.only(right: isLastItem ? 0 : itemSpacing),
                child: StoryHighlightCircle(
                  highlight: hl,
                  onTap: () => HighlightStoryViewerService.openHighlight(
                    userId: widget.userID,
                    highlight: hl,
                  ),
                  onLongPress: () {
                    final myUid = _myUserId;
                    if (widget.userID == myUid) {
                      noYesAlert(
                        title: 'profile.remove_highlight_title'.tr,
                        message: 'profile.remove_highlight_body'.tr,
                        cancelText: 'common.cancel'.tr,
                        yesText: 'profile.remove_highlight_confirm'.tr,
                        onYesPressed: () {
                          hlController.deleteHighlight(hl.id);
                        },
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
