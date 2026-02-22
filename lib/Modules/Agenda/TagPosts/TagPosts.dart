import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Core/Buttons/BackButtons.dart';
import '../../../Core/Helpers/RoadToTop/RoadToTop.dart';
import '../AgendaContent/AgendaContent.dart';
import 'TagPostsController.dart';

class TagPosts extends StatefulWidget {
  final String tag;

  const TagPosts({super.key, required this.tag});

  @override
  State<TagPosts> createState() => _TagPostsState();
}

class _TagPostsState extends State<TagPosts> {
  late TagPostsController controller;
  final ScrollController scrollController = ScrollController();
  int centeredIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TagPostsController(tag: widget.tag));
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Yaklaşık kart yüksekliği ile merkezdeki indexi hesapla
    final idx = ((scrollController.offset + (Get.height * 0.35)) / 700).floor();
    if (idx != centeredIndex && idx >= 0) {
      setState(() {
        centeredIndex = idx;
      });
    }
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
                      text: widget.tag.contains("#") ? widget.tag : "#${widget.tag}",
                    ),
                    const Expanded(
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  ],
                )
              else
                ListView.builder(
                  controller: scrollController,
                  itemCount: list.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return BackButtons(
                        text: widget.tag.contains("#") ? widget.tag : "#${widget.tag}",
                      );
                    }
                    final actualIndex = index - 1;
                    final model = list[actualIndex];
                    return Padding(
                      padding: EdgeInsets.only(top: actualIndex == 0 ? 10 : 0),
                      child: Column(
                        children: [
                          AgendaContent(
                            model: model,
                            isPreview: false,
                            shouldPlay: centeredIndex == actualIndex,
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
