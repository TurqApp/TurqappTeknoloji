part of 'creator_content.dart';

extension CreatorContentTextPart on CreatorContent {
  Widget textBody() {
    return Obx(() {
      final maxCaptionLength = PostCaptionLimits.forCurrentUser();
      return TextFieldTapRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          controller.refreshHashtagSuggestionsFromCursor();
                          controller.ensureTrendingHashtagsLoaded();
                        },
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: 14,
                        maxLength: maxCaptionLength,
                        buildCounter: (
                          BuildContext context, {
                          required int currentLength,
                          required bool isFocused,
                          required int? maxLength,
                        }) {
                          return null;
                        },
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(maxCaptionLength),
                          LineLimitingTextInputFormatter(14),
                        ],
                        readOnly: controller.waitingVideo.value,
                        onChanged: (val) {
                          controller.textChanged.value = val.trim().isNotEmpty;
                          controller.refreshHashtagSuggestionsFromCursor();
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
                        final indexInList = mainController.postList
                            .indexWhere((e) => e == model);
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
            Obx(() {
              if (!controller.showHashtagSuggestions.value) {
                return const SizedBox.shrink();
              }
              final items = controller.hashtagSuggestions;
              if (controller.hashtagSuggestionsLoading.value && items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 52,
                    child: Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                );
              }
              if (items.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 280),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      primary: false,
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,
                      physics: const ClampingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.14),
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final hashtag = normalizeComposerHashtag(item.hashtag);
                        return InkWell(
                          onTap: () =>
                              controller.applyTrendingHashtagSelection(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF4F5F7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '#',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hashtag,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'explore.tab.trending'.tr,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
