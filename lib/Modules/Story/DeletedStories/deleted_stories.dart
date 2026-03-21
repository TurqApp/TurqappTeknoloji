import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/deleted_stories_controller.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart'
    show StoryModel;

class DeletedStoriesView extends StatefulWidget {
  const DeletedStoriesView({super.key});

  @override
  State<DeletedStoriesView> createState() => _DeletedStoriesViewState();
}

class _DeletedStoriesViewState extends State<DeletedStoriesView> {
  late final DeletedStoriesController controller;
  late final String _pageLineBarTag =
      '${kDeletedStoriesPageLineBarTag}_${identityHashCode(this)}';
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existingController = DeletedStoriesController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = DeletedStoriesController.ensure();
      _ownsController = true;
    }
    Future<void>.delayed(Duration.zero, () {
      controller.fetch(initial: false, forceRemote: true);
    });
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(DeletedStoriesController.maybeFind(), controller)) {
      Get.delete<DeletedStoriesController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'story.deleted_stories.title'.tr),
            PageLineBar(
              barList: [
                'story.deleted_stories.tab_deleted'.tr,
                'story.deleted_stories.tab_expired'.tr,
              ],
              pageName: _pageLineBarTag,
              pageController: controller.pageController,
            ),
            Expanded(
              child: Obx(() {
                if (controller.list.isEmpty && controller.isLoading.value) {
                  return Center(child: CupertinoActivityIndicator());
                }
                return RefreshIndicator(
                  backgroundColor: Colors.black,
                  color: Colors.white,
                  onRefresh: () => controller.refresh(),
                  child: controller.list.isEmpty
                      ? _EmptyState()
                      : _TabbedContent(
                          controller: controller,
                          pageLineBarTag: _pageLineBarTag,
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.clock, size: 40, color: Colors.grey),
          SizedBox(height: 12),
          Text('story.deleted_stories.empty'.tr,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
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
      (e) => e.type == StoryElementType.image || e.type == StoryElementType.gif,
      orElse: () => model.elements.isNotEmpty
          ? model.elements.first
          : StoryElement(
              type: StoryElementType.text,
              content: '',
              width: 0,
              height: 0,
              position: Offset(0, 0),
            ),
    );
    final hasImage = first.type == StoryElementType.image ||
        first.type == StoryElementType.gif;
    final bg = (model.backgroundColor.a * 255.0).round().clamp(0, 255) == 0
        ? Colors.grey.shade100
        : model.backgroundColor.withValues(alpha: 0.25);
    final deletedStr = _relativeTime(deletedAt);

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
              offset: Offset(0, 4),
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
                      placeholder: (c, _) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (c, _, __) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  else
                    Container(color: bg),
                  // Üst gradient

                  // Silinme zamanı etiketi
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.trash,
                              size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            deletedStr,
                            style: TextStyle(color: Colors.white, fontSize: 12),
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
                          Icon(CupertinoIcons.share_up,
                              size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'common.share'.tr,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontFamily: "MontserratMedium"),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
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
  final String? reasonFilter; // 'manual' | 'expired' | null
  const _GridContent({required this.controller, this.reasonFilter});

  @override
  State<_GridContent> createState() => _GridContentState();
}

class _GridContentState extends State<_GridContent> {
  final user = CurrentUserService.instance;

  void _maybeFetchMore(int index, int total) {
    // Tüm hikayeler tek seferde çekiliyor; bu ekranda paging yok.
  }

  void _openViewer(
      {required int tappedIndex, required List<StoryModel> source}) {
    // Reorder so tapped first
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
    final c = widget.controller;
    // Filter by reason
    final filtered = c.list.where((m) {
      if (widget.reasonFilter == null) return true;
      final reason = c.deleteReasonById[m.id];
      if (reason != null && reason.isNotEmpty) {
        if (widget.reasonFilter == 'expired') {
          return reason == 'expired' || reason == 'expired_cf';
        }
        return reason == widget.reasonFilter || reason == 'manual';
      }
      final isExpired = DateTime.now().difference(m.createdAt).inHours >= 24;
      return widget.reasonFilter == 'expired' ? isExpired : !isExpired;
    }).toList();

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75, // dikdörtgen görünüm
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        _maybeFetchMore(index, filtered.length);
        final m = filtered[index];
        final delMs = c.deletedAtById[m.id] ?? 0;
        final when = delMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(delMs)
            : m.createdAt;
        return GestureDetector(
          onTap: () => _openViewer(tappedIndex: index, source: filtered),
          child: _StoryCard(
            model: m,
            deletedAt: when,
            onRestore: () async {
              await c.repost(m);
              AppSnackbar('story.deleted_stories.snackbar_title'.tr,
                  'story.deleted_stories.reposted'.tr);
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
              await c.deleteForever(m);
              AppSnackbar('story.deleted_stories.snackbar_title'.tr,
                  'story.deleted_stories.deleted_forever'.tr);
            },
          ),
        );
      },
    );
  }
}

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
    final c = widget.controller;
    // Reorder stories so tapped one starts first
    final all = List<StoryModel>.from(c.list);
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
    final c = widget.controller;
    final h = MediaQuery.of(context).size.height;
    final itemH = (h / 12).clamp(56.0, 120.0);
    // Filtrelenmiş listeyi hazırla
    final all = c.list;
    final filtered = all;

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        _maybeFetchMore(index);
        final m = filtered[index];
        final delMs = c.deletedAtById[m.id] ?? 0;
        final when = delMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(delMs)
            : m.createdAt;
        final first = m.elements.firstWhere(
          (e) =>
              e.type == StoryElementType.image ||
              e.type == StoryElementType.gif,
          orElse: () => m.elements.isNotEmpty
              ? m.elements.first
              : StoryElement(
                  type: StoryElementType.text,
                  content: '',
                  width: 0,
                  height: 0,
                  position: Offset(0, 0),
                ),
        );
        final hasImage = first.type == StoryElementType.image ||
            first.type == StoryElementType.gif;
        return GestureDetector(
          onTap: () => _openViewer(tappedIndex: index),
          child: Container(
            height: itemH,
            margin: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: first.content,
                            fit: BoxFit.cover,
                            placeholder: (c, _) =>
                                Container(color: Colors.grey.shade200),
                            errorWidget: (c, _, __) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child:
                                  Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(color: Colors.grey.shade100),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.trash,
                                size: 14, color: Colors.redAccent),
                            SizedBox(width: 6),
                            Text(
                              'story.deleted_stories.deleted_at'
                                  .trParams({'time': _relativeTime(when)}),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '${DateTime.fromMillisecondsSinceEpoch(m.createdAt.millisecondsSinceEpoch).toLocal()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await widget.controller.repost(m);
                    AppSnackbar('story.deleted_stories.snackbar_title'.tr,
                        'story.deleted_stories.reposted'.tr);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blueAccent.shade400),
                    padding: EdgeInsets.symmetric(horizontal: 5),
                  ),
                  child: Text(
                    'common.share'.tr,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueAccent,
                        fontFamily: "MontserratMedium"),
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
                    await widget.controller.deleteForever(m);
                    AppSnackbar('story.deleted_stories.snackbar_title'.tr,
                        'story.deleted_stories.deleted_forever'.tr);
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

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
  }
}
