import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class DenemeGrid extends StatelessWidget {
  const DenemeGrid({
    super.key,
    required this.model,
    required this.getData,
    this.isListLayout = false,
  });

  final SinavModel model;
  final Future<void> Function() getData;
  final bool isListLayout;

  Future<void> _shareExternally() async {
    await ShareActionGuard.run(() async {
      final shareId = 'practice-exam:${model.docID}';
      final shortTail =
          model.docID.length >= 8 ? model.docID.substring(0, 8) : model.docID;
      final fallbackId = 'practice-exam-$shortTail';
      final fallbackUrl = 'https://turqapp.com/e/$fallbackId';

      String shortUrl = fallbackUrl;
      try {
        shortUrl = await ShortLinkService().getEducationPublicUrl(
          shareId: shareId,
          title: model.sinavAdi,
          desc: model.sinavAciklama.isNotEmpty
              ? model.sinavAciklama
              : model.sinavTuru,
          imageUrl: model.cover.isNotEmpty ? model.cover : null,
        );
      } catch (_) {
        shortUrl = fallbackUrl;
      }

      if (shortUrl.trim().isEmpty || shortUrl.trim() == 'https://turqapp.com') {
        shortUrl = fallbackUrl;
      }

      await ShareLinkService.shareUrl(
        url: shortUrl,
        title: model.sinavAdi,
        subject: model.sinavAdi,
      );
    });
  }

  void _openCard() {
    if (model.userID == FirebaseAuth.instance.currentUser!.uid) {
      Get.dialog(
        AlertDialog(
          title: Text(
            model.sinavAdi,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
          content: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: model.cover,
              fit: BoxFit.cover,
            ),
          ),
          backgroundColor: Colors.white,
          actions: [
            _ownerAction(
              label: 'common.view'.tr,
              color: Colors.purpleAccent,
              onTap: () {
                Get.back();
                Get.to(() => DenemeSinaviPreview(model: model));
              },
            ),
            4.ph,
            _ownerAction(
              label: 'common.delete'.tr,
              color: Colors.red,
              onTap: () {
                Get.back();
                Future.delayed(const Duration(milliseconds: 300), () {
                  noYesAlert(
                    title: 'common.delete'.tr,
                    message: 'tests.delete_confirm'.tr,
                    cancelText: 'common.cancel'.tr,
                    yesText: 'common.delete'.tr,
                    onYesPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('practiceExams')
                          .doc(model.docID)
                          .delete();
                      await getData();
                    },
                  );
                });
              },
            ),
            4.ph,
            _ownerAction(
              label: 'tests.edit_title'.tr,
              color: Colors.indigo,
              onTap: () {
                Get.back();
                Get.to(() => SinavHazirla(sinavModel: model));
              },
            ),
            4.ph,
            _ownerAction(
              label: 'common.cancel'.tr,
              color: Colors.black,
              onTap: Get.back,
            ),
          ],
        ),
      );
      return;
    }
    Get.to(() => DenemeSinaviPreview(model: model));
  }

  Widget _ownerAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }

  String _formattedApplicationText(int count) {
    final scaled = count * 3;
    String value;
    if (scaled / 1000000 > 1) {
      value = '${(scaled / 1000000).toStringAsFixed(2)}M';
    } else if (scaled / 1000 > 1) {
      value = '${(scaled / 1000).toStringAsFixed(1)}B';
    } else {
      value = '$scaled';
    }
    return '${'practice.application_count'.tr}: $value';
  }

  Color _ctaColor(DenemeGridController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return Colors.green;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      return Colors.purple;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < model.bitis) {
      return Colors.black;
    }
    return Colors.pink;
  }

  String _ctaLabel(DenemeGridController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return 'practice.apply_now'.tr;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      return 'scholarship.closed'.tr;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < model.bitis) {
      return 'practice.started'.tr;
    }
    return 'practice.start_now'.tr;
  }

  Widget _buildMedia({double? width, double? height, double radius = 12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: Colors.indigo.withValues(alpha: 0.08),
        child: model.cover.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: model.cover,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CupertinoActivityIndicator(color: Colors.black),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.quiz_outlined,
                  color: Colors.indigo,
                  size: 30,
                ),
              )
            : const Center(
                child: Icon(
                  Icons.quiz_outlined,
                  color: Colors.indigo,
                  size: 30,
                ),
              ),
      ),
    );
  }

  Widget _buildGridCard(
    DenemeGridController controller,
    SavedPracticeExamsController savedController,
  ) {
    return PasajGridCard(
      onTap: _openCard,
      media: _buildMedia(radius: 12),
      overlay: GestureDetector(
        onTap: model.docID.trim().isEmpty
            ? null
            : () => savedController.toggleSavedExam(model.docID),
        child: SizedBox(
          width: PasajListCardMetrics.gridOverlayButtonSize,
          height: PasajListCardMetrics.gridOverlayButtonSize,
          child: Center(
            child: Obx(
              () => Icon(
                savedController.savedExamIds.contains(model.docID)
                    ? AppIcons.saved
                    : AppIcons.save,
                color: Colors.white,
                size: PasajListCardMetrics.gridOverlayIconSize,
                shadows: const [
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      lines: [
        Text(
          model.sinavAdi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.lineOne,
        ),
        Text(
          formatTimestamp(model.timeStamp.toInt()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.gridLineTwo(Colors.indigo),
        ),
        Text(
          model.sinavTuru,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.detail,
        ),
        Obx(
          () => Row(
            children: [
              Icon(
                CupertinoIcons.person_2_fill,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  controller.isLoadingApplicants.value
                      ? 'common.loading'.tr
                      : _formattedApplicationText(
                          controller.toplamBasvuru.value,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PasajCardStyles.gridLineFour(
                    PasajCardStyles.lineFourColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      cta: Obx(
        () => Container(
          height: PasajListCardMetrics.gridCtaHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ctaColor(controller),
            borderRadius: const BorderRadius.all(
              Radius.circular(PasajListCardMetrics.gridCtaRadius),
            ),
          ),
          child: Text(
            _ctaLabel(controller),
            style: PasajCardStyles.gridCta,
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(
    DenemeGridController controller,
    SavedPracticeExamsController savedController,
  ) {
    const metrics = PasajListCardMetrics.regular;
    return GestureDetector(
      onTap: _openCard,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMedia(
                width: metrics.mediaSize,
                height: metrics.mediaSize,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: metrics.railHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: metrics.detailRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            model.sinavAdi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PasajCardStyles.lineOne,
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      SizedBox(
                        height: metrics.detailRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 14,
                                color: PasajCardStyles.lineTwoColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formatTimestamp(model.timeStamp.toInt()),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PasajCardStyles.lineTwo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      SizedBox(
                        height: metrics.detailRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.doc_text,
                                size: 14,
                                color: PasajCardStyles.lineFourColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  model.sinavTuru,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PasajCardStyles.detail,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      SizedBox(
                        height: metrics.ctaHeight,
                        child: Obx(
                          () => Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.person_2_fill,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    controller.isLoadingApplicants.value
                                        ? 'common.loading'.tr
                                        : _formattedApplicationText(
                                            controller.toplamBasvuru.value,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: PasajCardStyles.lineFour,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: metrics.railWidth,
                height: metrics.railHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EducationShareIconButton(
                          onTap: _shareExternally,
                          size: metrics.actionButtonSize,
                          iconSize: metrics.actionIconSize,
                        ),
                        SizedBox(width: metrics.railActionGap),
                        Obx(
                          () => AppHeaderActionButton(
                            onTap: model.docID.trim().isEmpty
                                ? null
                                : () => savedController.toggleSavedExam(
                                      model.docID,
                                    ),
                            size: metrics.actionButtonSize,
                            child: Icon(
                              savedController.savedExamIds.contains(model.docID)
                                  ? AppIcons.saved
                                  : AppIcons.save,
                              size: metrics.actionIconSize,
                              color: savedController.savedExamIds.contains(
                                model.docID,
                              )
                                  ? Colors.orange
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.railSectionGap),
                    SizedBox(height: metrics.middleSlotHeight),
                    const Spacer(),
                    SizedBox(
                      width: metrics.railWidth,
                      child: Obx(
                        () => Container(
                          height: metrics.ctaHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _ctaColor(controller),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _ctaLabel(controller),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: metrics.ctaFontSize,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DenemeGridController controller = Get.put(
      DenemeGridController(),
      tag: model.docID,
    );
    final SavedPracticeExamsController savedController =
        Get.isRegistered<SavedPracticeExamsController>()
            ? Get.find<SavedPracticeExamsController>()
            : Get.put(SavedPracticeExamsController());
    controller.initData(model);

    return isListLayout
        ? _buildListCard(controller, savedController)
        : _buildGridCard(controller, savedController);
  }
}
