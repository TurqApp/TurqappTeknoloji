import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/StoryCommentUser/story_comment_user.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/story_comments_controller.dart';

class StoryComments extends StatefulWidget {
  final String storyID;
  final String nickname;
  final bool isMyStory;

  const StoryComments({
    super.key,
    required this.storyID,
    required this.nickname,
    required this.isMyStory,
  });

  @override
  State<StoryComments> createState() => _StoryCommentsState();
}

class _StoryCommentsState extends State<StoryComments> {
  late final StoryCommentsController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'story_comments_${widget.storyID}_${identityHashCode(this)}';
    controller = StoryCommentsController.maybeFind(tag: _controllerTag) ??
        StoryCommentsController.ensure(
          nickname: widget.nickname,
          storyID: widget.storyID,
          tag: _controllerTag,
        );
    controller.getData();
  }

  @override
  void dispose() {
    if (StoryCommentsController.maybeFind(tag: _controllerTag) != null &&
        identical(
          StoryCommentsController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<StoryCommentsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: AppSheetHeader(
                title: 'story.comments_title'.trParams({
                  'count': '${controller.totalComment.value}',
                }),
              ),
            ),
          ),
          Obx(() {
            return controller.list.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: controller.list.length,
                      itemBuilder: (context, index) {
                        final model = controller.list[index];
                        return StoryCommentUser(
                          model: model,
                          storyID: widget.storyID,
                          isMyStory: widget.isMyStory,
                        );
                      },
                    ),
                  )
                : Expanded(
                    child: Center(
                    child: EmptyRow(text: 'story.no_comments'.tr),
                  ));
          }),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final gifUrl = controller.selectedGifUrl.value.trim();
                        if (gifUrl.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: gifUrl,
                                  cacheManager: TurqImageCacheManager.instance,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  placeholderFadeInDuration: Duration.zero,
                                  placeholder: (context, _) => Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.grey.withAlpha(18),
                                    child: const Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.grey.withAlpha(18),
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  key: const ValueKey(
                                    IntegrationTestKeys
                                        .actionStoryCommentClearGif,
                                  ),
                                  onTap: controller.clearSelectedGif,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(140),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.xmark,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextField(
                        key: const ValueKey(
                            IntegrationTestKeys.inputStoryComment),
                        controller: controller.commentTextfield,
                        focusNode: controller.commentFocus,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(280)
                        ],
                        decoration: InputDecoration(
                          hintText: 'story.add_comment_for'.trParams({
                            'nickname': controller.nickname,
                          }),
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontFamily: "MontserratMedium",
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                          height: 1.8,
                        ),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                key: const ValueKey(
                  IntegrationTestKeys.actionStoryCommentGifPicker,
                ),
                onTap: () => controller.pickGif(context),
                child: Container(
                  width: 36,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'GIF',
                    style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'MontserratBold',
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey(IntegrationTestKeys.actionStoryCommentSend),
                onPressed: () {
                  controller.setComment();
                },
                icon: Icon(CupertinoIcons.arrow_right_circle_fill,
                    color: Colors.black, size: 35),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              )
            ],
          )
        ],
      ),
    );
  }
}
