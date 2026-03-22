import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content_controller.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Themes/app_icons.dart';

import '../job_finder_controller.dart';

class JobContent extends StatefulWidget {
  final bool isGrid;
  final JobModel model;
  const JobContent({super.key, required this.model, required this.isGrid});

  @override
  State<JobContent> createState() => _JobContentState();
}

class _JobContentState extends State<JobContent> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final JobContentController controller;

  bool get isGrid => widget.isGrid;
  JobModel get model => widget.model;

  String get _workTypeText {
    if (model.calismaTuru.isEmpty) {
      return 'pasaj.job_finder.salary_not_specified'.tr;
    }
    return model.calismaTuru.join(', ');
  }

  String get _cityTownText {
    final city = model.city.trim();
    final town = model.town.trim();
    if (city.isNotEmpty && town.isNotEmpty) {
      return '$city, $town';
    }
    if (city.isNotEmpty) return city;
    if (town.isNotEmpty) return town;
    return 'pasaj.market.location_missing'.tr;
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = 'job_content_${_baseTag}_${identityHashCode(this)}';
    _ownsController =
        JobContentController.maybeFind(tag: _controllerTag) == null;
    controller = JobContentController.ensure(tag: _controllerTag);
    _primeSavedState();
  }

  @override
  void didUpdateWidget(covariant JobContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.docID != model.docID) {
      _primeSavedState();
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
            JobContentController.maybeFind(tag: _controllerTag), controller)) {
      Get.delete<JobContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  String get _baseTag {
    final docId = model.docID.trim();
    if (docId.isNotEmpty) return docId;
    return 'job_fallback_${model.timeStamp}_${model.brand.hashCode}_${model.logo.hashCode}_${model.meslek.hashCode}';
  }

  void _primeSavedState() {
    if (model.docID.trim().isNotEmpty) {
      controller.primeSavedState(model.docID);
    }
  }

  Widget _buildLogo({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    final normalizedUrl = imageUrl.trim();
    final hasLogoValue = normalizedUrl.isNotEmpty;
    final fallback = Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F4F7),
      alignment: Alignment.center,
      child: Icon(
        Icons.work_outline_rounded,
        color: Colors.grey.shade500,
        size: ((width ?? height ?? 96) * 0.32).clamp(22, 40).toDouble(),
      ),
    );

    if (!hasLogoValue) {
      return borderRadius == null
          ? fallback
          : ClipRRect(borderRadius: borderRadius, child: fallback);
    }

    final image = CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
    return borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius, child: image);
  }

  @override
  Widget build(BuildContext context) {
    return isGrid ? gridView(controller) : listingView(controller);
  }

  Widget listingView(JobContentController controller) {
    const metrics = PasajListCardMetrics.regular;
    return GestureDetector(
      key: ValueKey(IntegrationTestKeys.jobItem(_baseTag)),
      onLongPress: () => controller.reactivateEndedJob(model),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 6, top: 6),
        child: GestureDetector(
          onTap: () async {
            await Get.to(() => JobDetails(model: model));
            final finderController = JobFinderController.maybeFind();
            if (finderController != null) {
              await finderController.refreshJob(model.docID);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
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
                    child: _buildLogo(
                      imageUrl: model.logo.trim(),
                      width: metrics.mediaSize,
                      height: metrics.railHeight,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
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
                              model.ilanBasligi.isNotEmpty
                                  ? model.meslek
                                  : model.brand,
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
                              model.ilanBasligi.isNotEmpty
                                  ? model.ilanBasligi
                                  : model.meslek,
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
                              _workTypeText,
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
                              _cityTownText,
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
                            onTap: () => controller.shareJob(model),
                            size: metrics.actionButtonSize,
                            child: Icon(
                              AppIcons.share,
                              size: metrics.actionIconSize,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: metrics.railActionGap),
                          Obx(() {
                            return AppHeaderActionButton(
                              onTap: model.docID.trim().isEmpty
                                  ? null
                                  : () => controller.toggleSave(model.docID),
                              size: metrics.actionButtonSize,
                              child: Icon(
                                controller.saved.value
                                    ? AppIcons.saved
                                    : AppIcons.save,
                                size: metrics.actionIconSize,
                                color: controller.saved.value
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
                            await Get.to(() => JobDetails(model: model));
                            final finderController =
                                JobFinderController.maybeFind();
                            if (finderController != null) {
                              await finderController.refreshJob(model.docID);
                            }
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
                              'pasaj.market.inspect'.tr,
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
      ),
    );
  }

  Widget gridView(JobContentController controller) {
    return PasajGridCard(
      key: ValueKey(IntegrationTestKeys.jobItem(_baseTag)),
      onTap: () => Get.to(JobDetails(model: model)),
      onLongPress: () => controller.reactivateEndedJob(model),
      media: _buildLogo(
        imageUrl: model.logo.trim(),
        width: null,
        height: null,
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      overlay: Obx(
        () => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: model.docID.trim().isEmpty
              ? null
              : () => controller.toggleSave(model.docID),
          child: SizedBox(
            width: PasajListCardMetrics.gridOverlayButtonSize,
            height: PasajListCardMetrics.gridOverlayButtonSize,
            child: Center(
              child: Icon(
                controller.saved.value ? AppIcons.saved : AppIcons.save,
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
          model.ilanBasligi.isNotEmpty ? model.meslek : model.brand,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.lineOne,
        ),
        Text(
          model.ilanBasligi.isNotEmpty ? model.ilanBasligi : model.meslek,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.gridLineTwo(PasajCardStyles.lineTwoColor),
        ),
        Text(
          _workTypeText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.detail,
        ),
        Text(
          _cityTownText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.gridLineFour(PasajCardStyles.lineFourColor),
        ),
      ],
      cta: GestureDetector(
        onTap: () => Get.to(JobDetails(model: model)),
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
            'pasaj.market.inspect'.tr,
            style: PasajCardStyles.gridCta,
          ),
        ),
      ),
    );
  }
}
