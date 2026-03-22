part of 'creator_content.dart';

extension CreatorContentTextPart on CreatorContent {
  Widget textBody() {
    return Obx(() {
      return Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Scrollbar(
                    child: TextField(
                      key: ValueKey(
                        IntegrationTestKeys.composerText(model.index),
                      ),
                      focusNode: controller.focus,
                      controller: controller.textEdit,
                      textCapitalization: TextCapitalization.sentences,
                      onTap: () {
                        final position = mainController.postList.indexWhere(
                          (post) => post.index == model.index,
                        );
                        if (position != -1) {
                          mainController.selectedIndex.value = position;
                        }
                      },
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
                      maxLines: 14,
                      inputFormatters: [LineLimitingTextInputFormatter(14)],
                      readOnly: controller.waitingVideo.value,
                      onChanged: (val) {
                        controller.textChanged.value = val.trim().isNotEmpty;
                      },
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: controller.waitingVideo.value
                            ? 'post_creator.processing_wait'.tr
                            : 'post_creator.placeholder'.tr,
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              ),
              if (mainController.postList.length > 1)
                Transform.translate(
                  offset: const Offset(10, -15),
                  child: IconButton(
                    onPressed: () {
                      final indexInList =
                          mainController.postList.indexWhere((e) => e == model);
                      if (indexInList != -1) {
                        final previousSelectedIndex =
                            mainController.selectedIndex.value;
                        if (indexInList == 0) {
                          for (final post in mainController.postList) {
                            if (CreatorContentController.maybeFind(
                                  tag: post.index.toString(),
                                ) !=
                                null) {
                              Get.delete<CreatorContentController>(
                                tag: post.index.toString(),
                                force: true,
                              );
                            }
                          }
                          mainController.postList.assignAll(
                            [PostCreatorModel(index: 0, text: "")],
                          );
                          mainController.postList.refresh();
                          mainController.resetComposerItemIndexSeed(1);
                          mainController.selectedIndex.value = 0;
                        } else {
                          if (CreatorContentController.maybeFind(
                                tag: model.index.toString(),
                              ) !=
                              null) {
                            Get.delete<CreatorContentController>(
                              tag: model.index.toString(),
                              force: true,
                            );
                          }
                          mainController.postList.removeAt(indexInList);
                          mainController.postList.refresh();
                          final lastIndex = mainController.postList.isEmpty
                              ? 0
                              : mainController.postList.length - 1;
                          final nextSelectedIndex = previousSelectedIndex >
                                  indexInList
                              ? previousSelectedIndex - 1
                              : previousSelectedIndex == indexInList
                                  ? indexInList.clamp(0, lastIndex)
                                  : previousSelectedIndex.clamp(0, lastIndex);
                          mainController.selectedIndex.value =
                              nextSelectedIndex;
                        }
                      }
                    },
                    icon: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.black,
                      size: 15,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
