import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/TagPosts.dart';
import '../AgendaContent/AgendaContent.dart';
import 'TopTagsContoller.dart';

class TopTags extends StatelessWidget {
  TopTags({super.key});
  final TopTagsController controller = Get.put(TopTagsController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Öne Çıkanlar"),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.black,
                color: Colors.white,
                onRefresh: () async {
                  controller.lastDoc = null;
                  controller.hasMore = true;
                  controller.agendaList.clear();
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
                        final itemKey = controller.getAgendaKey(actualIndex);
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
              final title =
                  item.hasHashtag ? "#${item.hashtag}" : item.hashtag;
              return Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Get.to(() => TagPosts(tag: item.hashtag));
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
                                  "${i + 1} - Türkiye tarihinde gündemde",
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
