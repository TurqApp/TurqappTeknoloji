import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:turqappv2/Services/post_interaction_service.dart';
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

class ShortsContent extends StatelessWidget {
  static const List<String> _flagReasons = <String>[
    'Uyuşturucu',
    'Kumar',
    'Çıplaklık',
    'Dolandırıcılık',
    'Şiddet',
    'Spam',
    'Diğer',
  ];
  static final RxSet<String> _flaggedPostIds = <String>{}.obs;
  final PostsModel model;
  final HLSVideoAdapter videoPlayerController;
  final Function(bool) volumeOff;
  final void Function(String updatedDocId)? onEdited;

  ShortsContent({
    super.key,
    required this.model,
    required this.videoPlayerController,
    required this.volumeOff,
    this.onEdited, // <-- yeni parametre
  });

  late final ShortContentController controller;

  bool get _isBlackBadgeUser {
    final rozet = (CurrentUserService.instance.currentUser?.rozet ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i');
    return rozet == 'siyah' || rozet == 'black';
  }

  @override
  Widget build(BuildContext context) {
    controller = Get.put(
      ShortContentController(postID: model.docID, model: model),
      tag: model.docID,
    );
    controller.fullscreen.value = true;
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
      return Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () {
              controller.fullscreen.value = !controller.fullscreen.value;
            },
            onDoubleTap: () {
              controller.toggleLike();
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
                videoPlayerController.play();
              }
            },
            onHorizontalDragEnd: (details) async {
              if (details.velocity.pixelsPerSecond.dx < 0) {
                videoPlayerController.pause();
                await Get.to(() => SocialProfile(userID: model.userID));
                videoPlayerController.play();
              }
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          if (controller.fullscreen.value) userInfoBar(context),
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
      );
    });
  }
}
