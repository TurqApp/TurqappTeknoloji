part of 'profile_view.dart';

extension _ProfileViewSectionsPart on _ProfileViewState {
  Widget _buildLinksAndHighlightsRow() {
    final uid = _myUserId;
    if (uid.isEmpty) return const SizedBox.shrink();

    final tag = 'highlights_$uid';
    final hlController =
        StoryHighlightsController.ensure(userId: uid, tag: tag);

    return Obx(() {
      const rowHeight = 90.0;
      const itemWidth = 70.0;
      const itemSpacing = 18.0;
      final mixedItems = <Map<String, dynamic>>[];
      for (final model in socialMediaController.list) {
        mixedItems.add({
          'type': 'link',
          'createdAt': int.tryParse(model.docID) ?? 0,
          'data': model,
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
        (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int),
      );

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
              return Padding(
                padding: const EdgeInsets.only(right: itemSpacing),
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
}
