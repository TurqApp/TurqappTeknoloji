part of 'deleted_stories.dart';

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AppStateView.empty(
      title: 'story.deleted_stories.empty'.tr,
      icon: CupertinoIcons.clock,
    );
  }
}

class _StoryCard extends StatelessWidget {
  final StoryModel model;
  final DateTime deletedAt;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _StoryCard({
    required this.model,
    required this.deletedAt,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final first = model.elements.firstWhere(
      (element) =>
          element.type == StoryElementType.image ||
          element.type == StoryElementType.gif,
      orElse: () => model.elements.isNotEmpty
          ? model.elements.first
          : StoryElement(
              type: StoryElementType.text,
              content: '',
              width: 0,
              height: 0,
              position: const Offset(0, 0),
            ),
    );
    final hasImage = first.type == StoryElementType.image ||
        first.type == StoryElementType.gif;
    final bg = (model.backgroundColor.a * 255.0).round().clamp(0, 255) == 0
        ? Colors.grey.shade100
        : model.backgroundColor.withValues(alpha: 0.25);
    final deletedStr = _relativeDeletedTime(deletedAt);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: first.content,
                      fit: BoxFit.cover,
                      placeholder: (context, _) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (context, _, __) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(color: bg),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.trash,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            deletedStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: IconButton(
                      onPressed: onRestore,
                      icon: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.share_up,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'common.share'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabbedContent extends StatelessWidget {
  final DeletedStoriesController controller;
  final String pageLineBarTag;

  const _TabbedContent({
    required this.controller,
    required this.pageLineBarTag,
  });

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller.pageController,
      onPageChanged: (idx) {
        syncPageLineBarSelection(pageLineBarTag, idx);
      },
      children: [
        _GridContent(controller: controller, reasonFilter: 'manual'),
        _GridContent(controller: controller, reasonFilter: 'expired'),
      ],
    );
  }
}

class _GridContent extends StatefulWidget {
  final DeletedStoriesController controller;
  final String? reasonFilter;

  const _GridContent({required this.controller, this.reasonFilter});

  @override
  State<_GridContent> createState() => _GridContentState();
}

class _GridContentState extends State<_GridContent> {
  final user = CurrentUserService.instance;

  void _maybeFetchMore(int index, int total) {
    // Tüm hikayeler tek seferde çekiliyor; bu ekranda paging yok.
  }

  void _openViewer({
    required int tappedIndex,
    required List<StoryModel> source,
  }) {
    final reordered = [
      ...source.sublist(tappedIndex),
      ...source.sublist(0, tappedIndex),
    ];
    final startedUser = StoryUserModel(
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      fullName: user.fullName,
      userID: user.userId,
      stories: reordered,
    );
    Get.to(() => StoryViewer(
          startedUser: startedUser,
          storyOwnerUsers: [startedUser],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final filtered = controller.list.where((story) {
      if (widget.reasonFilter == null) return true;
      final reason = controller.deleteReasonById[story.id];
      if (reason != null && reason.isNotEmpty) {
        if (widget.reasonFilter == 'expired') {
          return reason == 'expired' || reason == 'expired_cf';
        }
        return reason == widget.reasonFilter || reason == 'manual';
      }
      final isExpired =
          DateTime.now().difference(story.createdAt).inHours >= 24;
      return widget.reasonFilter == 'expired' ? isExpired : !isExpired;
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        _maybeFetchMore(index, filtered.length);
        final story = filtered[index];
        final deletedMs = controller.deletedAtById[story.id] ?? 0;
        final when = deletedMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(deletedMs)
            : story.createdAt;
        return GestureDetector(
          onTap: () => _openViewer(tappedIndex: index, source: filtered),
          child: _StoryCard(
            model: story,
            deletedAt: when,
            onRestore: () async {
              await controller.repost(story);
              AppSnackbar(
                'story.deleted_stories.snackbar_title'.tr,
                'story.deleted_stories.reposted'.tr,
              );
            },
            onDelete: () async {
              final confirmed = await Get.dialog<bool>(
                CupertinoAlertDialog(
                  title: Text('story.permanent_delete'.tr),
                  content: Text('story.permanent_delete_message'.tr),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Get.back(result: false),
                      child: Text('common.cancel'.tr),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Get.back(result: true),
                      child: Text('common.delete'.tr),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await controller.deleteForever(story);
              AppSnackbar(
                'story.deleted_stories.snackbar_title'.tr,
                'story.deleted_stories.deleted_forever'.tr,
              );
            },
          ),
        );
      },
    );
  }
}
