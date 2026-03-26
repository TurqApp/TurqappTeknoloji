import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Core/Buttons/back_buttons.dart';
import '../../../Core/Helpers/RoadToTop/road_to_top.dart';
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
    controller.updateVisibleIndexByPosition(scrollController);
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
                    controller.updateVisibleIndexByPosition(scrollController);
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
                        child: Column(
                          children: [
                            AgendaContent(
                              key: controller.getAgendaKey(docId: model.docID),
                              model: model,
                              isPreview: false,
                              instanceTag:
                                  controller.agendaInstanceTag(model.docID),
                              shouldPlay:
                                  controller.centeredIndex.value == actualIndex,
                            ),
                            SizedBox(
                              height: 1,
                              child: Divider(color: Colors.grey.withAlpha(40)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (list.isNotEmpty)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                    child: RoadToTop(),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
