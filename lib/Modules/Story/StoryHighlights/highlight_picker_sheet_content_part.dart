part of 'highlight_picker_sheet.dart';

extension _HighlightPickerSheetContentPart on _HighlightPickerSheetState {
  Widget _buildPage(BuildContext context) {
    final uid = _currentUid;
    if (uid.isEmpty) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.viewInsets.bottom;
    final tag = 'highlights_$uid';
    final controller = StoryHighlightsController.ensure(userId: uid, tag: tag);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: BoxConstraints(
            maxHeight: media.size.height - topInset - bottomInset - 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 18),
                _buildSheetHeader(),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.isLoading.value &&
                      controller.highlights.isEmpty &&
                      !_isCreatingNew) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }
                  if (controller.highlights.isEmpty && !_isCreatingNew) {
                    return _buildEmptyCreateState(controller);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 8),
                        child: Text(
                          'story.highlights_collections'.tr,
                          style: const TextStyle(
                            color: Color(0xFF6D6D6D),
                            fontSize: 12,
                            fontFamily: 'MontserratSemiBold',
                          ),
                        ),
                      ),
                      ...controller.highlights.map(
                        (h) => _buildHighlightTile(controller, h),
                      ),
                      const SizedBox(height: 6),
                      if (_isCreatingNew)
                        _buildNewHighlightForm(controller)
                      else
                        _buildCreateAnotherTile(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFD7D7D7),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              color: Colors.black,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'story.highlights_title'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'story.highlights_subtitle'.tr,
                  style: const TextStyle(
                    color: Color(0xFF6D6D6D),
                    fontSize: 12,
                    height: 1.35,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile(StoryHighlightsController controller, dynamic h) {
    final alreadyContainsStory = h.storyIds.contains(widget.storyId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        minTileHeight: 72,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 48,
            height: 48,
            child: h.coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: h.coverUrl,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: const Color(0xFFF2F2F2),
                    child: const Icon(
                      CupertinoIcons.collections_solid,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
          ),
        ),
        title: Text(
          h.title,
          style: const TextStyle(
            fontFamily: 'MontserratSemiBold',
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          'story.highlights_story_count'.trParams({
            'count': h.storyIds.length.toString(),
          }),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A8A8A),
            fontFamily: 'MontserratMedium',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alreadyContainsStory)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await controller.deleteHighlight(h.id);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F4F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!alreadyContainsStory) {
            await controller.addStoryToHighlight(h.id, widget.storyId);
          }
          Get.back();
        },
      ),
    );
  }
}
