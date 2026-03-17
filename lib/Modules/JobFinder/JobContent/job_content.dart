import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content_controller.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Themes/app_icons.dart';

import '../job_finder_controller.dart';

class JobContent extends StatelessWidget {
  final bool isGrid;
  final JobModel model;
  JobContent({super.key, required this.model, required this.isGrid});
  late final JobContentController controller;
  @override
  Widget build(BuildContext context) {
    controller = Get.put(JobContentController(), tag: model.docID);
    controller.checkSaved(model.docID);
    return isGrid ? gridView() : listingView();
  }

  Widget listingView() {
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
                    width: 96,
                    height: 96,
                    child: CachedNetworkImage(
                      imageUrl: model.logo,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.ilanBasligi.isNotEmpty
                              ? model.ilanBasligi
                              : model.meslek,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 8),
                        Text(
                          model.calismaTuru.isEmpty
                              ? 'Belirtilmedi'
                              : model.calismaTuru.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                        const SizedBox(height: 6),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 108,
                  height: 96,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppHeaderActionButton(
                            onTap: () => controller.shareJob(model),
                            child: Icon(
                              AppIcons.share,
                              size: AppIconSurface.kIconSize,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Obx(() {
                            return AppHeaderActionButton(
                              onTap: () => controller.toggleSave(model.docID),
                              child: Icon(
                                controller.saved.value
                                    ? AppIcons.saved
                                    : AppIcons.save,
                                size: AppIconSurface.kIconSize,
                                color: controller.saved.value
                                    ? Colors.orange
                                    : Colors.black87,
                              ),
                            );
                          }),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 108,
                        child: GestureDetector(
                          onTap: () async {
                            await Get.to(() => JobDetails(model: model));
                            final finderController =
                                Get.find<JobFinderController>();
                            await finderController.refreshJob(model.docID);
                          },
                          child: Container(
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                            child: const Text(
                              'İncele',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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

  Widget gridView() {
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
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        topLeft: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: model.logo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Obx(
                      () => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.toggleSave(model.docID),
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
                    model.calismaTuru.length <= 1
                        ? model.calismaTuru.join(", ")
                        : "${model.calismaTuru.take(1).join(", ")} +${model.calismaTuru.length - 1}",
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
                    "${model.kacKm.toStringAsFixed(2)} km\n${model.city}, ${model.town}",
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
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Get.to(JobDetails(model: model)),
                      child: Container(
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Text(
                          'İncele',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
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
