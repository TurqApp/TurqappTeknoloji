part of 'deleted_stories.dart';

class _VerticalStrip extends StatefulWidget {
  final DeletedStoriesController controller;

  const _VerticalStrip({required this.controller});

  @override
  State<_VerticalStrip> createState() => _VerticalStripState();
}

class _VerticalStripState extends State<_VerticalStrip> {
  final user = CurrentUserService.instance;

  void _maybeFetchMore(int index) {
    // Tüm hikayeler tek seferde çekiliyor; bu ekranda paging yok.
  }

  void _openViewer({required int tappedIndex}) {
    final controller = widget.controller;
    final all = List<StoryModel>.from(controller.list);
    final reordered = [
      ...all.sublist(tappedIndex),
      ...all.sublist(0, tappedIndex),
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
    final height = MediaQuery.of(context).size.height;
    final itemHeight = (height / 12).clamp(56.0, 120.0);
    final filtered = controller.list;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        _maybeFetchMore(index);
        final story = filtered[index];
        final deletedMs = controller.deletedAtById[story.id] ?? 0;
        final when = deletedMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(deletedMs)
            : story.createdAt;
        final first = story.elements.firstWhere(
          (element) =>
              element.type == StoryElementType.image ||
              element.type == StoryElementType.gif,
          orElse: () => story.elements.isNotEmpty
              ? story.elements.first
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

        return GestureDetector(
          onTap: () => _openViewer(tappedIndex: index),
          child: Container(
            height: itemHeight,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasImage
                        ? CachedNetworkImage(
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
                        : Container(color: Colors.grey.shade100),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.trash,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'story.deleted_stories.deleted_at'.trParams(
                                  {'time': _relativeDeletedTime(when)}),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateTime.fromMillisecondsSinceEpoch(story.createdAt.millisecondsSinceEpoch).toLocal()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await widget.controller.repost(story);
                    AppSnackbar(
                      'story.deleted_stories.snackbar_title'.tr,
                      'story.deleted_stories.reposted'.tr,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blueAccent.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                  ),
                  child: Text(
                    'common.share'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blueAccent,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
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
                    await widget.controller.deleteForever(story);
                    AppSnackbar(
                      'story.deleted_stories.snackbar_title'.tr,
                      'story.deleted_stories.deleted_forever'.tr,
                    );
                  },
                  icon: const Icon(
                    CupertinoIcons.delete,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
