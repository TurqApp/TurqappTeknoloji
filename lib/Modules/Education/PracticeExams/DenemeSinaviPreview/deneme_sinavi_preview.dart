import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_owner_card.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'deneme_sinavi_preview_content_part.dart';
part 'deneme_sinavi_preview_sections_part.dart';

class DenemeSinaviPreview extends StatefulWidget {
  const DenemeSinaviPreview({super.key, required this.model});

  final SinavModel model;
  @override
  State<DenemeSinaviPreview> createState() => _DenemeSinaviPreviewState();
}

class _DenemeSinaviPreviewState extends State<DenemeSinaviPreview> {
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();
  late final String _tag;
  late final DenemeSinaviPreviewController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'practice_exam_preview_${widget.model.docID}_${identityHashCode(this)}';
    final existing = maybeFindDenemeSinaviPreviewController(tag: _tag);
    _ownsController = existing == null;
    controller = existing ??
        ensureDenemeSinaviPreviewController(tag: _tag, model: widget.model);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindDenemeSinaviPreviewController(tag: _tag),
          controller,
        )) {
      Get.delete<DenemeSinaviPreviewController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }

  Future<void> _handlePrimaryAction(
    DenemeSinaviPreviewController controller,
  ) async {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      await controller.addBasvuru();
      return;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      AppSnackbar(
        'practice.application_closed_title'.tr,
        'practice.application_closed_body'.tr,
      );
      return;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      if (controller.sinavaGirebilir.value) {
        if (controller.dahaOnceBasvurdu.value) {
          Get.to(
            () => DenemeSinaviYap(
              model: controller.model,
              sinaviBitir: controller.sinaviBitirAlert,
              showGecersizAlert: controller.showGecersizAlert,
              uyariAtla: false,
            ),
          );
        } else {
          AppSnackbar(
            'practice.not_applied_title'.tr,
            'practice.not_applied_body'.tr,
          );
        }
      } else {
        AppSnackbar(
          'practice.not_allowed_title'.tr,
          'practice.not_allowed_body'.tr,
        );
      }
      return;
    }
    if (controller.model.public) {
      Get.to(
        () => DenemeSinaviYap(
          model: controller.model,
          sinaviBitir: controller.sinaviBitirAlert,
          showGecersizAlert: controller.showGecersizAlert,
          uyariAtla: true,
        ),
      );
      return;
    }
    AppSnackbar(
      'practice.finished_title'.tr,
      'practice.finished_body'.tr,
    );
  }

  Color _ctaColor(DenemeSinaviPreviewController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return Colors.teal;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      return Colors.purple;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      return Colors.black;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value > controller.model.bitis &&
        controller.model.public == false) {
      return Colors.red;
    }
    return Colors.indigo;
  }

  String _ctaLabel(DenemeSinaviPreviewController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return controller.dahaOnceBasvurdu.value
          ? 'practice.applied_short'.tr
          : 'practice.apply_now'.tr;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      final minutes =
          ((controller.examTime.value - controller.currentTime.value) /
                  (60 * 1000))
              .floor();
      return 'practice.closed_starts_in'
          .trParams({'minutes': minutes.toString()});
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      return 'practice.started'.tr;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value > controller.model.bitis &&
        controller.model.public == false) {
      return 'practice.finished_short'.tr;
    }
    return 'practice.start_now'.tr;
  }

  Widget _pullDownMenu(DenemeSinaviPreviewController controller) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(
              () => ReportUser(
                userID: controller.model.userID,
                postID: controller.model.docID,
                commentID: '',
              ),
            );
          },
          title: 'practice.report_exam'.tr,
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => AppHeaderActionButton(
        onTap: showMenu,
        child: const Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }
}
