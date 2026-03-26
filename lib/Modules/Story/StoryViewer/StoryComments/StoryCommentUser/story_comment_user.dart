import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/story_comments_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../../../Core/rozet_content.dart';
import '../../../../../Models/story_comment_model.dart';
import '../../../../SocialProfile/social_profile.dart';
import 'story_comment_user_controller.dart';

class StoryCommentUser extends StatefulWidget {
  final StoryCommentModel model;
  final String storyID;
  final bool isMyStory;

  const StoryCommentUser(
      {super.key,
      required this.model,
      required this.storyID,
      required this.isMyStory});

  @override
  State<StoryCommentUser> createState() => _StoryCommentUserState();
}

class _StoryCommentUserState extends State<StoryCommentUser> {
  late final StoryCommentUserController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'story_comment_user_${widget.model.docID}_${identityHashCode(this)}';
    final existingController =
        maybeFindStoryCommentUserController(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ensureStoryCommentUserController(
        tag: _controllerTag,
      );
      _ownsController = true;
    }
    controller.getUserData(widget.model.userID);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindStoryCommentUserController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<StoryCommentUserController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.grey.withAlpha(1)),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.model.userID != _currentUserId) {
                        Get.to(
                            () => SocialProfile(userID: widget.model.userID));
                      }
                    },
                    child: ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: controller.avatarUrl.value != ""
                            ? CachedNetworkImage(
                                imageUrl: controller.avatarUrl.value,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (widget.model.userID != _currentUserId) {
                                  Get.to(() => SocialProfile(
                                      userID: widget.model.userID));
                                }
                              },
                              child: Text(
                                controller.nickname.value,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontFamily: "MontserratBold"),
                              ),
                            ),
                            RozetContent(
                              size: 14,
                              userID: widget.model.userID,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                timeAgoMetin(widget.model.timeStamp),
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontFamily: "MontserratMedium"),
                              ),
                            )
                          ],
                        ),
                        if (widget.model.metin.trim().isNotEmpty)
                          Text(
                            widget.model.metin,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: "MontserratMedium"),
                          ),
                        if (widget.model.gif.trim().isNotEmpty) ...[
                          SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: widget.model.gif.trim(),
                              cacheManager: TurqImageCacheManager.instance,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholderFadeInDuration: Duration.zero,
                              placeholder: (context, _) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey.withAlpha(18),
                                child: Center(
                                  child: CupertinoActivityIndicator(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey.withAlpha(18),
                                child: Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  if (widget.isMyStory || widget.model.userID == _currentUserId)
                    Transform.translate(
                      offset: Offset(0, -10),
                      child: IconButton(
                        onPressed: () {
                          noYesAlert(
                              title: 'common.delete'.tr,
                              message: 'story.comment_delete_message'.tr,
                              onYesPressed: () {
                                final store = StoryCommentsController.maybeFind(
                                  tag: widget.storyID,
                                );
                                final index =
                                    store?.list.indexOf(widget.model) ?? -1;
                                if (index >= 0) {
                                  store!.list.removeAt(index);
                                  store.totalComment.value--;
                                }
                                StoryRepository.ensure().deleteStoryComment(
                                  widget.storyID,
                                  commentId: widget.model.docID,
                                );
                              });
                        },
                        icon: Icon(CupertinoIcons.trash,
                            color: Colors.black, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 18,
                      ),
                    )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: SizedBox(
                height: 2,
                child: Divider(
                  color: Colors.grey.withAlpha(20),
                )),
          )
        ],
      );
    });
  }
}
