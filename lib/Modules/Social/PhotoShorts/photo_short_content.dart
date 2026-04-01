import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/post_story_share_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Themes/app_tokens.dart';
import 'package:turqappv2/Core/sizes.dart';
import '../../../Core/BottomSheets/no_yes_alert.dart';
import '../../../Core/formatters.dart';
import '../../../Core/rozet_content.dart';
import '../../SocialProfile/ReportUser/report_user.dart';
import '../hashtag_text_post.dart';
import '../PostSharers/post_sharers.dart';
import '../../PostCreator/post_creator.dart';
import 'photo_short_content_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';
import '../../../Services/post_count_manager.dart';

part 'photo_short_content_body_part.dart';
part 'photo_short_content_state_part.dart';

class PhotoShortContent extends StatefulWidget {
  final PostsModel model;
  const PhotoShortContent({super.key, required this.model});

  @override
  State<PhotoShortContent> createState() => _PhotoShortContentState();
}

class _PhotoShortContentState extends State<PhotoShortContent> {
  late final PhotoShortsContentController controller;
  late final PageController _pageController;
  late final String _controllerTag;
  late final bool _ownsController;
  int _currentPage = 0;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  StoryUserModel? _resolveStoryUser() {
    final rowController = maybeFindStoryRowController();
    if (rowController == null) return null;
    for (final user in rowController.users) {
      if (user.userID == widget.model.userID && user.stories.isNotEmpty) {
        return user;
      }
    }
    return null;
  }

  List<StoryUserModel> _storyUsersSnapshot() {
    final rowController = maybeFindStoryRowController();
    if (rowController == null) return const <StoryUserModel>[];
    return rowController.users.toList(growable: false);
  }

  Future<void> _openAuthorProfile() async {
    if (widget.model.userID == _currentUserId) return;
    await Get.to(() => SocialProfile(userID: widget.model.userID));
  }

  Future<void> _openAvatarStoryOrProfile() async {
    final storyUser = _resolveStoryUser();
    if (storyUser != null && storyUser.stories.isNotEmpty) {
      await Get.to(() => StoryViewer(
            startedUser: storyUser,
            storyOwnerUsers: _storyUsersSnapshot(),
          ));
      return;
    }
    await _openAuthorProfile();
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = 'PhotoShortContent_${widget.model.docID}';
    _ownsController =
        maybeFindPhotoShortsContentController(tag: _controllerTag) == null;
    controller = ensurePhotoShortsContentController(
      model: widget.model,
      tag: _controllerTag,
    );
    controller.fetchUserData(widget.model.userID);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_ownsController &&
        identical(
          maybeFindPhotoShortsContentController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PhotoShortsContentController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox.expand(
        child: Stack(
          children: [
            SizedBox.expand(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.model.img.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return PinchZoom(
                    child: GestureDetector(
                      onTap: () {
                        controller.fullScreen.value =
                            !controller.fullScreen.value;
                      },
                      onDoubleTap: () {
                        controller.toggleLike();
                      },
                      child: CachedNetworkImage(
                        memCacheHeight: 2000,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        imageUrl: widget.model.img[index],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Üst progress bar kaldırıldı; yalnızca altta nokta bar kullanılıyor
            // Üstte kullanıcı bilgileri (geri, profil, menü vs.) görünür
            if (!controller.fullScreen.value)
              SafeArea(child: userInfoBar(context)),

            // Üstte nokta bar (üstteki çizgiler yerine)
            if (widget.model.img.length > 1 && !controller.fullScreen.value)
              Positioned(
                top: MediaQuery.of(context).padding.top + 52,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.model.img.length, (i) {
                    final bool isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: isActive ? 10 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            if (controller.gizlendi.value) gonderiGizlendi(context),
            if (controller.arsiv.value) gonderiArsivlendi(context),
            Obx(() => controller.silindi.value
                ? AnimatedOpacity(
                    opacity: controller.silindiOpacity.value,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: gonderiSilindi(context),
                  )
                : const SizedBox.shrink()),

            // OriginalUserAttribution for PhotoShortContent
            if (!controller.fullScreen.value)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SharedPostLabel(
                        originalUserID: widget.model.originalUserID,
                        fontSize: AppTypography.postAttribution.fontSize!,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
