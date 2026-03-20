import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content_controller.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Themes/app_icons.dart';

import '../job_finder_controller.dart';

class JobContent extends StatelessWidget {
  final bool isGrid;
  final JobModel model;
  JobContent({super.key, required this.model, required this.isGrid});

  String get _controllerTag {
    final docId = model.docID.trim();
    if (docId.isNotEmpty) return docId;
    return 'job_fallback_${model.timeStamp}_${model.brand.hashCode}_${model.logo.hashCode}_${model.meslek.hashCode}';
  }

  String get _workTypeText {
    if (model.calismaTuru.isEmpty) {
      return 'pasaj.job_finder.salary_not_specified'.tr;
    }
    return model.calismaTuru.join(', ');
  }

  String get _gridWorkTypeText {
    if (model.calismaTuru.isEmpty) {
      return 'pasaj.job_finder.salary_not_specified'.tr;
    }
    if (model.calismaTuru.length == 1) {
      return model.calismaTuru.first;
    }
    return '${model.calismaTuru.first} +${model.calismaTuru.length - 1}';
  }

  String get _distanceAndLocationText {
    final parts = <String>[];
    if (model.kacKm.isFinite && model.kacKm > 0) {
      parts.add('${model.kacKm.toStringAsFixed(2)} km');
    }

    final city = model.city.trim();
    final town = model.town.trim();
    if (city.isNotEmpty && town.isNotEmpty) {
      parts.add('$city, $town');
    } else if (city.isNotEmpty) {
      parts.add(city);
    } else if (town.isNotEmpty) {
      parts.add(town);
    }

    return parts.isEmpty
        ? 'pasaj.market.location_missing'.tr
        : parts.join('\n');
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

  Widget _buildResolvedLogo({
    required JobContentController controller,
    required double? width,
    required double? height,
    required BorderRadius borderRadius,
  }) {
    return FutureBuilder<JobModel?>(
      future: controller.resolveFreshJob(model),
      initialData: model,
      builder: (context, snapshot) {
        final freshLogo = snapshot.data?.logo.trim() ?? '';
        final imageUrl = freshLogo.isNotEmpty ? freshLogo : model.logo.trim();
        return _buildLogo(
          imageUrl: imageUrl,
          width: width,
          height: height,
          borderRadius: borderRadius,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<JobContentController>(tag: _controllerTag)
            ? Get.find<JobContentController>(tag: _controllerTag)
            : Get.put(JobContentController(), tag: _controllerTag);
    if (model.docID.trim().isNotEmpty) {
      controller.checkSaved(model.docID);
    }
    return isGrid ? gridView(controller) : listingView(controller);
  }

  Widget listingView(JobContentController controller) {
    const metrics = PasajListCardMetrics.regular;
    return GestureDetector(
      onLongPress: () => controller.reactivateEndedJob(model),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 6, top: 6),
        child: GestureDetector(
          onTap: () async {
            await Get.to(() => JobDetails(model: model));
            final finderController = Get.find<JobFinderController>();
            await finderController.refreshJob(model.docID);
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
                    height: metrics.mediaSize,
                    child: _buildResolvedLogo(
                      controller: controller,
                      width: metrics.mediaSize,
                      height: metrics.mediaSize,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model.ilanBasligi.isNotEmpty
                            ? model.ilanBasligi
                            : model.meslek,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      SizedBox(height: metrics.contentGap / 2),
                      Text(
                        model.ilanBasligi.isNotEmpty
                            ? model.meslek
                            : model.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      Text(
                        _workTypeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "${model.city}, ${model.town}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: metrics.contentGap),
                      SizedBox(height: metrics.detailRowHeight),
                    ],
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
                                Get.find<JobFinderController>();
                            await finderController.refreshJob(model.docID);
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
    const metrics = PasajListCardMetrics.regular;
    return GestureDetector(
      onTap: () => Get.to(JobDetails(model: model)),
      onLongPress: () => controller.reactivateEndedJob(model),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: Colors.grey.withAlpha(50))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildResolvedLogo(
                      controller: controller,
                      width: null,
                      height: null,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        topLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Obx(
                      () => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: model.docID.trim().isEmpty
                            ? null
                            : () => controller.toggleSave(model.docID),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Icon(
                              controller.saved.value
                                  ? AppIcons.saved
                                  : AppIcons.save,
                              size: 24,
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.ilanBasligi.isNotEmpty
                        ? model.ilanBasligi
                        : model.meslek,
                    maxLines: 1,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: "MontserratBold"),
                  ),
                  Text(
                    _gridWorkTypeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                  Text(
                    model.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontFamily: "MontserratMedium"),
                  ),
                  Text(
                    _distanceAndLocationText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: metrics.railWidth,
                      child: GestureDetector(
                        onTap: () => Get.to(JobDetails(model: model)),
                        child: Container(
                          height: metrics.ctaHeight,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
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
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
