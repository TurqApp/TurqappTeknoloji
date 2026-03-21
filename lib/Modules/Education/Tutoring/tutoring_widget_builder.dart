import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';

String? getCurrentUserId() {
  final userId = CurrentUserService.instance.userId;
  return userId.isNotEmpty ? userId : null;
}

class TutoringWidgetBuilder extends StatelessWidget {
  final List<TutoringModel> tutoringList;
  final bool isGridView;
  final Widget? infoMessage;
  final bool allowReactivate;

  const TutoringWidgetBuilder({
    super.key,
    required this.tutoringList,
    required this.isGridView,
    this.infoMessage,
    this.allowReactivate = false,
  });

  Future<void> _shareExternally(TutoringModel tutoring) async {
    await ShareActionGuard.run(() async {
      final shareId = 'tutoring:${tutoring.docID}';
      final shortTail = tutoring.docID.length >= 8
          ? tutoring.docID.substring(0, 8)
          : tutoring.docID;
      final fallbackId = 'tutoring-$shortTail';
      final fallbackUrl = 'https://turqapp.com/e/$fallbackId';

      String shortUrl = fallbackUrl;
      try {
        shortUrl = await ShortLinkService().getEducationPublicUrl(
          shareId: shareId,
          title: tutoring.baslik,
          desc: tutoring.brans.isNotEmpty ? tutoring.brans : 'Özel ders ilanı',
          imageUrl: tutoring.imgs != null && tutoring.imgs!.isNotEmpty
              ? tutoring.imgs!.first
              : null,
        );
      } catch (_) {
        shortUrl = fallbackUrl;
      }

      if (shortUrl.trim().isEmpty || shortUrl.trim() == 'https://turqapp.com') {
        shortUrl = fallbackUrl;
      }

      await ShareLinkService.shareUrl(
        url: shortUrl,
        title: tutoring.baslik,
        subject: tutoring.baslik,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedController = Get.isRegistered<SavedTutoringsController>()
        ? Get.find<SavedTutoringsController>()
        : Get.put(SavedTutoringsController());
    final tutoringController = Get.isRegistered<TutoringController>()
        ? Get.find<TutoringController>()
        : Get.put(TutoringController());
    final myTutoringsController = Get.isRegistered<MyTutoringsController>()
        ? Get.find<MyTutoringsController>()
        : null;
    final currentUserId = getCurrentUserId();

    if (tutoringList.isEmpty) {
      return Center(child: infoMessage ?? const SizedBox.shrink());
    }

    if (isGridView) {
      return Column(
        children: PasajListingAdLayout.buildTwoColumnGridChildren(
          items: tutoringList,
          horizontalSpacing: 8,
          rowSpacing: 8,
          itemBuilder: (tutoring, index) {
            final lessonPlace = _lessonPlaceText(tutoring);
            final imageUrl = _imageUrl(tutoring);
            return PasajGridCard(
              onTap: () async {
                if (allowReactivate &&
                    tutoring.ended == true &&
                    myTutoringsController != null) {
                  await myTutoringsController.reactivateEndedTutoring(tutoring);
                  return;
                }
                await Get.to(() => TutoringDetail(), arguments: tutoring);
              },
              media: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _fallbackImage(),
                      )
                    : _fallbackImage(),
              ),
              overlay: Obx(
                () => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleSave(
                    tutoring: tutoring,
                    currentUserId: currentUserId,
                    controller: tutoringController,
                    savedController: savedController,
                  ),
                  child: SizedBox(
                    width: PasajListCardMetrics.gridOverlayButtonSize,
                    height: PasajListCardMetrics.gridOverlayButtonSize,
                    child: Center(
                      child: Icon(
                        savedController.savedTutoringIds
                                .contains(tutoring.docID)
                            ? AppIcons.saved
                            : AppIcons.save,
                        size: PasajListCardMetrics.gridOverlayIconSize,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              lines: [
                Text(
                  tutoring.baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PasajCardStyles.lineOne,
                ),
                Text(
                  tutoring.brans,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PasajCardStyles.gridLineTwo(
                    PasajCardStyles.lineTwoColor,
                  ),
                ),
                Text(
                  lessonPlace,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PasajCardStyles.detail,
                ),
                Text(
                  _cityDistrictText(tutoring),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PasajCardStyles.gridLineFour(
                    PasajCardStyles.lineFourColor,
                  ),
                ),
              ],
              cta: GestureDetector(
                onTap: () => Get.to(
                  () => TutoringDetail(),
                  arguments: tutoring,
                ),
                child: Container(
                  height: PasajListCardMetrics.gridCtaHeight,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(
                      Radius.circular(PasajListCardMetrics.gridCtaRadius),
                    ),
                  ),
                  child: Text(
                    allowReactivate && tutoring.ended == true
                        ? 'admin.reports.restore'.tr
                        : 'common.view'.tr,
                    style: PasajCardStyles.gridCta,
                  ),
                ),
              ),
            );
          },
          adBuilder: (slot) => AdmobKare(
            key: ValueKey('tutoring-grid-ad-$slot'),
          ),
        ),
      );
    }

    return Column(
      children: PasajListingAdLayout.buildListChildren(
        items: tutoringList,
        itemBuilder: (tutoring, index) {
          final lessonPlace = _lessonPlaceText(tutoring);
          final imageUrl = _imageUrl(tutoring);
          const metrics = PasajListCardMetrics.regular;
          return Padding(
            padding:
                const EdgeInsets.only(left: 15, right: 15, bottom: 6, top: 6),
            child: GestureDetector(
              onTap: () async {
                if (allowReactivate &&
                    tutoring.ended == true &&
                    myTutoringsController != null) {
                  await myTutoringsController.reactivateEndedTutoring(tutoring);
                  return;
                }
                await Get.to(() => TutoringDetail(), arguments: tutoring);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.18)),
                  color: Colors.white,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: SizedBox(
                        width: metrics.mediaSize,
                        height: metrics.railHeight,
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _fallbackImage(),
                              )
                            : _fallbackImage(),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                                  tutoring.baslik,
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
                                child: Text(
                                  tutoring.brans,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PasajCardStyles.lineTwo,
                                ),
                              ),
                            ),
                            SizedBox(height: metrics.contentGap),
                            SizedBox(
                              height: metrics.detailRowHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  lessonPlace,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PasajCardStyles.detail,
                                ),
                              ),
                            ),
                            SizedBox(height: metrics.contentGap),
                            SizedBox(
                              height: metrics.ctaHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _cityDistrictText(tutoring),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PasajCardStyles.lineFour,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: metrics.railWidth,
                      height: metrics.railHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppHeaderActionButton(
                                onTap: () => _shareExternally(tutoring),
                                size: metrics.actionButtonSize,
                                child: Icon(
                                  AppIcons.share,
                                  size: metrics.actionIconSize,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: metrics.railActionGap),
                              Obx(() {
                                final isSaved = savedController.savedTutoringIds
                                    .contains(tutoring.docID);
                                return AppHeaderActionButton(
                                  onTap: () => _toggleSave(
                                    tutoring: tutoring,
                                    currentUserId: currentUserId,
                                    controller: tutoringController,
                                    savedController: savedController,
                                  ),
                                  size: metrics.actionButtonSize,
                                  child: Icon(
                                    isSaved ? AppIcons.saved : AppIcons.save,
                                    size: metrics.actionIconSize,
                                    color: isSaved
                                        ? Colors.orange
                                        : Colors.black87,
                                  ),
                                );
                              }),
                            ],
                          ),
                          SizedBox(height: metrics.railSectionGap),
                          SizedBox(height: metrics.middleSlotHeight),
                          const Spacer(),
                          SizedBox(
                            width: metrics.railWidth,
                            child: GestureDetector(
                              onTap: () async {
                                if (allowReactivate &&
                                    tutoring.ended == true &&
                                    myTutoringsController != null) {
                                  await myTutoringsController
                                      .reactivateEndedTutoring(tutoring);
                                  return;
                                }
                                await Get.to(
                                  () => TutoringDetail(),
                                  arguments: tutoring,
                                );
                              },
                              child: Container(
                                height: metrics.ctaHeight,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Text(
                                  allowReactivate && tutoring.ended == true
                                      ? 'admin.reports.restore'.tr
                                      : 'common.view'.tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: metrics.ctaFontSize,
                                    fontFamily: 'MontserratMedium',
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
        },
        adBuilder: (slot) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: AdmobKare(
            key: ValueKey('tutoring-list-ad-$slot'),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSave({
    required TutoringModel tutoring,
    required String? currentUserId,
    required TutoringController controller,
    required SavedTutoringsController savedController,
  }) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveTutoring)) {
      return;
    }
    if (currentUserId == null) return;
    final isSaved = savedController.savedTutoringIds.contains(tutoring.docID);
    final success = await controller.toggleFavorite(
      tutoring.docID,
      currentUserId,
      isSaved,
    );
    if (!success) return;
    if (isSaved) {
      savedController.removeSavedTutoring(tutoring.docID);
    } else {
      savedController.addSavedTutoring(tutoring.docID);
    }
  }

  String _lessonPlaceText(TutoringModel tutoring) {
    if (tutoring.dersYeri.isEmpty) return 'Ders Yeri Belirtilmedi';
    final first = tutoring.dersYeri.first;
    if (tutoring.dersYeri.length == 1) return first;
    return '$first +${tutoring.dersYeri.length - 1}';
  }

  String _cityDistrictText(TutoringModel tutoring) {
    final city = tutoring.sehir.trim();
    final district = tutoring.ilce.trim();
    if (city.isNotEmpty && district.isNotEmpty) return '$city, $district';
    if (city.isNotEmpty) return city;
    if (district.isNotEmpty) return district;
    return 'pasaj.market.location_missing'.tr;
  }

  String _imageUrl(TutoringModel tutoring) {
    if (tutoring.imgs == null || tutoring.imgs!.isEmpty) return '';
    return tutoring.imgs!.first;
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(CupertinoIcons.photo, color: Colors.grey),
    );
  }
}
