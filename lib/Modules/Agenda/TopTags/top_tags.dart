import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import '../AgendaContent/agenda_content.dart';
import 'top_tags_contoller.dart';

class TopTags extends StatefulWidget {
  const TopTags({super.key});

  @override
  State<TopTags> createState() => _TopTagsState();
}

class _TopTagsState extends State<TopTags> {
  late final TopTagsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existingController = TopTagsController.maybeFind();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = TopTagsController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(TopTagsController.maybeFind(), controller)) {
      Get.delete<TopTagsController>(force: true);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(CupertinoIcons.back,
                        size: 24, color: Colors.black),
                  ),
                  Expanded(
                    child: Text(
                      'explore.tab.trending'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: "MontserratBold",
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 68),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.black,
                color: Colors.white,
                onRefresh: () async {
                  controller.resetFeedState();
                  await controller.fetchAgendaBigData(initial: true);
                  await controller.getTags();
                },
                child: Obx(() {
                  final centeredIndex = controller.centeredIndex.value;

                  controller.lastCenteredIndex = centeredIndex;

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      controller.updateVisibleIndexByPosition(
                        notification.metrics,
                        context,
                      );
                      return false;
                    },
                    child: ListView.builder(
                      controller: controller.scrollController,
                      itemCount: controller.agendaList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return header();
                        }

                        final actualIndex = index - 1;
                        if (actualIndex >= controller.agendaList.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final model = controller.agendaList[actualIndex];
                        final itemKey =
                            controller.getAgendaKey(docId: model.docID);
                        final isCentered =
                            controller.centeredIndex.value == actualIndex;

                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: 5, top: actualIndex == 0 ? 15 : 0),
                          child: Column(
                            children: [
                              AgendaContent(
                                key: itemKey,
                                model: model,
                                isPreview: false,
                                instanceTag:
                                    controller.agendaInstanceTag(model.docID),
                                shouldPlay: isCentered,
                              ),
                              SizedBox(
                                height: 2,
                                child: Divider(
                                  color: Colors.grey.withAlpha(50),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget header() {
    return Obx(() {
      final items = controller.tags.take(30).toList();
      return Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Builder(builder: (_) {
              final item = items[i];
              final title = item.hasHashtag ? "#${item.hashtag}" : item.hashtag;
              return Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      controller.centeredIndex.value = -1;
                      Get.to(() => TagPosts(tag: item.hashtag))?.then((_) {
                        controller.resumeCenteredPost();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'explore.trending_rank'
                                        .trParams({'index': '${i + 1}'}),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontFamily: "MontserratBold",
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Icon(
                                CupertinoIcons.chevron_right,
                                color: Colors.black38,
                                size: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      height: 1,
                      child: Divider(
                        color: Colors.grey.withAlpha(50),
                      ),
                    ),
                  )
                ],
              );
            }),
          ]
        ],
      );
    });
  }
}
