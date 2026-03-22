import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/username_lookup_repository.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/post_story_share_service.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comments.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import '../../Core/formatters.dart';
import '../../Core/Helpers/clickable_text_content.dart';
import '../../Core/redirection_link.dart';
import '../../Core/rozet_content.dart';
import '../../Core/sizes.dart';
import '../../Themes/app_fonts.dart';
import '../Agenda/TagPosts/tag_posts.dart';
import '../Social/PostSharers/post_sharers.dart';
import '../PostCreator/post_creator.dart';
import '../SocialProfile/social_profile.dart';
import 'short_content_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';

part 'short_content_body_part.dart';

class ShortsContent extends StatefulWidget {
  final PostsModel model;
  final HLSVideoAdapter videoPlayerController;
  final Function(bool) volumeOff;
  final void Function(String updatedDocId)? onEdited;
  final bool isActive;
  final bool showOverlayControls;
  final VoidCallback? onToggleOverlay;
  final Future<void> Function()? onDoubleTapLike;
  final Future<void> Function()? onSwipeRight;

  const ShortsContent({
    super.key,
    required this.model,
    required this.videoPlayerController,
    required this.volumeOff,
    this.onEdited, // <-- yeni parametre
    required this.isActive,
    this.showOverlayControls = true,
    this.onToggleOverlay,
    this.onDoubleTapLike,
    this.onSwipeRight,
  });

  @override
  State<ShortsContent> createState() => _ShortsContentState();
}

class _ShortsContentState extends State<ShortsContent> {
  late final ShortContentController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  PostsModel get model => widget.model;
  HLSVideoAdapter get videoPlayerController => widget.videoPlayerController;
  Function(bool) get volumeOff => widget.volumeOff;
  void Function(String updatedDocId)? get onEdited => widget.onEdited;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  void resumeIfActive() {
    if (!widget.isActive) return;
    videoPlayerController.play();
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = model.docID;
    _ownsController =
        ShortContentController.maybeFind(tag: _controllerTag) == null;
    controller = ShortContentController.ensure(
      postID: model.docID,
      model: model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (_ownsController &&
          identical(
            ShortContentController.maybeFind(tag: _controllerTag),
            controller,
          )) {
        Get.delete<ShortContentController>(tag: _controllerTag);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.gizlendi.value) {
      videoPlayerController.pause();
    }

    if (controller.arsivlendi.value) {
      videoPlayerController.pause();
    }

    if (controller.silindi.value) {
      videoPlayerController.pause();
    }

    return Obx(() {
      final showOverlay = widget.onToggleOverlay == null
          ? controller.fullscreen.value
          : widget.showOverlayControls;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (widget.onToggleOverlay != null) {
            widget.onToggleOverlay!();
          } else {
            controller.fullscreen.value = !controller.fullscreen.value;
          }
        },
        onDoubleTap: () {
          if (widget.onDoubleTapLike != null) {
            widget.onDoubleTapLike!();
          } else {
            controller.toggleLike();
          }
          HapticFeedback.mediumImpact();
        },
        onLongPressStart: (v) {
          if (videoPlayerController.value.isInitialized) {
            videoPlayerController.pause();
            HapticFeedback.lightImpact();
          }
        },
        onLongPressEnd: (v) {
          if (videoPlayerController.value.isInitialized) {
            resumeIfActive();
          }
        },
        onHorizontalDragEnd: (details) async {
          if (details.velocity.pixelsPerSecond.dx > 500 &&
              widget.onSwipeRight != null) {
            videoPlayerController.pause();
            await widget.onSwipeRight!();
            resumeIfActive();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            const SizedBox.expand(),
            if (showOverlay) userInfoBar(context),
            if (controller.gizlendi.value) gonderiGizlendi(context),
            if (controller.arsivlendi.value) gonderiArsivlendi(context),
            Obx(() => controller.silindi.value
                ? AnimatedOpacity(
                    opacity: controller.silindiOpacity.value,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: gonderiSilindi(context),
                  )
                : const SizedBox.shrink())
          ],
        ),
      );
    });
  }
}
