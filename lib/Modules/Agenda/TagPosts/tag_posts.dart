import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../Core/Buttons/back_buttons.dart';
import '../AgendaContent/agenda_content.dart';
import 'tag_posts_controller.dart';

class TagPosts extends StatefulWidget {
  final String tag;

  const TagPosts({super.key, required this.tag});

  @override
  State<TagPosts> createState() => _TagPostsState();
}

class _TagPostsState extends State<TagPosts> {
  late TagPostsController controller;
  late final bool _ownsController;
  final ScrollController scrollController = ScrollController();
  late final String _controllerTag;
  bool _centerSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.tag.trim();
    final existingController = maybeFindTagPostsController(tag: _controllerTag);
    controller = ensureTagPostsController(tag: widget.tag);
    _ownsController = existingController == null;
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    if (_ownsController &&
        identical(
          maybeFindTagPostsController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<TagPostsController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  void _onScroll() {
    _scheduleRenderedCenterSync();
  }

  void _scheduleRenderedCenterSync() {
    if (_centerSyncScheduled) return;
    _centerSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSyncScheduled = false;
      if (!mounted) return;
      controller.updateVisibleIndexByRenderedItems(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final list = controller.list;
          return Stack(
            children: [
              if (list.isEmpty)
                Column(
                  children: [
                    BackButtons(
                      text: widget.tag.contains("#")
                          ? widget.tag
                          : "#${widget.tag}",
                    ),
                    const Expanded(
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  ],
                )
              else
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    _scheduleRenderedCenterSync();
                    return false;
                  },
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: list.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return BackButtons(
                          text: widget.tag.contains("#")
                              ? widget.tag
                              : "#${widget.tag}",
                        );
                      }
                      final actualIndex = index - 1;
                      final model = list[actualIndex];
                      return Padding(
                        padding:
                            EdgeInsets.only(top: actualIndex == 0 ? 10 : 0),
                        child: VisibilityDetector(
                          key: Key('tag_posts_visibility_${model.docID}'),
                          onVisibilityChanged: (info) {
                            controller.onPostVisibilityChanged(
                              actualIndex,
                              info.visibleFraction,
                            );
                          },
                          child: Column(
                            children: [
                              Obx(() {
                                final shouldPlay =
                                    controller.centeredIndex.value ==
                                        actualIndex;
                                if (shouldPlay && model.hasPlayableVideo) {
                                  debugPrint(
                                    '[TagPostsPlayTarget] index=$actualIndex '
                                    'doc=${model.docID}',
                                  );
                                }
                                return AgendaContent(
                                  key: controller.getAgendaKey(
                                    docId: model.docID,
                                  ),
                                  model: model,
                                  isPreview: false,
                                  instanceTag:
                                      controller.agendaInstanceTag(model.docID),
                                  shouldPlay: shouldPlay,
                                );
                              }),
                              SizedBox(
                                height: 1,
                                child:
                                    Divider(color: Colors.grey.withAlpha(40)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
