import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';

import '../../Themes/app_assets.dart';

class JobFinder extends StatelessWidget {
  JobFinder({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });
  final bool embedded;
  final bool showEmbeddedControls;
  static bool _bannerWarmupTriggered = false;
  final controller = JobFinderController.ensure(permanent: true);

  @override
  Widget build(BuildContext context) {
    if (!_bannerWarmupTriggered) {
      _bannerWarmupTriggered = true;
      unawaited(
        AdmobBannerWarmupService.ensure().warmForPasajEntry(
          surfaceKey: 'job_finder',
        ),
      );
    }

    final content = Column(
      children: [
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(child: _kesfetTab(context)),
      ],
    );

    if (embedded) {
      return Stack(
        children: [
          Column(
            children: [
              Expanded(child: content),
              GlobalLoader(),
            ],
          ),
          if (showEmbeddedControls && AdminAccessService.isKnownAdminSync())
            Positioned(
              right: 20,
              bottom: 20,
              child: ActionButton(
                context: context,
                menuItems: [
                  PullDownMenuItem(
                    icon: CupertinoIcons.slider_horizontal_3,
                    title: 'pasaj.common.slider_admin'.tr,
                    onTap: () => Get.to(
                      () => SliderAdminView(
                        sliderId: 'is_bul',
                        title: 'pasaj.job_finder.title'.tr,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Standalone header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 8),
                    TypewriterText(text: "pasaj.job_finder.title".tr),
                  ],
                ),
                Obx(() {
                  return TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => controller.showIlSec(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.red),
                          const SizedBox(width: 3),
                          Text(
                            controller.sehir.value.isNotEmpty
                                ? controller.sehir.value
                                : "pasaj.common.all_turkiye".tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            Expanded(child: content),
            GlobalLoader(),
          ],
        ),
      ),
      floatingActionButton: AdminAccessService.isKnownAdminSync()
          ? ActionButton(
              context: context,
              menuItems: [
                PullDownMenuItem(
                  icon: CupertinoIcons.slider_horizontal_3,
                  title: 'pasaj.common.slider_admin'.tr,
                  onTap: () => Get.to(
                    () => SliderAdminView(
                      sliderId: 'is_bul',
                      title: 'pasaj.job_finder.title'.tr,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  // ─── Tab 1: Keşfet ───
  Widget _kesfetTab(BuildContext context) {
    return Obx(() {
      if (!controller.listingSelectionReady.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (controller.isLoading.value && controller.list.isEmpty) {
        return Column(
          children: [
            _kesfetHeader(isSearching: false, context: context),
            const Expanded(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ],
        );
      }
      if (controller.list.isEmpty) {
        return Column(
          children: [
            _kesfetHeader(isSearching: false, context: context),
            const SizedBox(height: 50),
            EmptyRow(text: "common.no_results".tr),
          ],
        );
      }

      final query = controller.search.text.trim();
      final isSearching = query.length >= 2;
      final tumTurkiye =
          controller.isAllTurkeySelection(controller.sehir.value);

      final dataList = isSearching
          ? controller.aramaSonucu
          : (tumTurkiye
              ? controller.list
              : controller.list
                  .where(
                      (e) => e.city.toString().contains(controller.sehir.value))
                  .toList());

      if (controller.listingSelection.value == 0) {
        if (dataList.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kesfetHeader(isSearching: isSearching, context: context),
              EmptyRow(
                text: isSearching
                    ? "pasaj.job_finder.no_search_result".tr
                    : "pasaj.job_finder.no_city_listing".tr,
              ),
            ],
          );
        }
        return ListView(
          children: [
            _kesfetHeader(isSearching: isSearching, context: context),
            ...PasajListingAdLayout.buildListChildren(
              items: dataList,
              itemBuilder: (item, index) => JobContent(
                model: item,
                isGrid: false,
              ),
              adBuilder: (slot) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: AdmobKare(
                  key: ValueKey('job-list-ad-$slot'),
                ),
              ),
            ),
          ],
        );
      } else {
        if (dataList.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kesfetHeader(isSearching: isSearching, context: context),
              EmptyRow(
                text: isSearching
                    ? "pasaj.job_finder.no_search_result".tr
                    : "pasaj.job_finder.no_city_listing".tr,
              ),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              _kesfetHeader(isSearching: isSearching, context: context),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  children: PasajListingAdLayout.buildTwoColumnGridChildren(
                    items: dataList,
                    horizontalSpacing: 8,
                    rowSpacing: 8,
                    itemBuilder: (item, index) =>
                        JobContent(model: item, isGrid: true),
                    adBuilder: (slot) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AdmobKare(
                        key: ValueKey('job-grid-ad-$slot'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _kesfetHeader(
      {required bool isSearching, required BuildContext context}) {
    return Column(
      children: [
        EducationSlider(
          sliderId: 'is_bul',
          imageList: [AppAssets.job1, AppAssets.job2, AppAssets.job3],
        ),
        if (!embedded) ...[
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TurqSearchBar(
              controller: controller.search,
              hintText: "pasaj.job_finder.search_hint".tr,
            ),
          ),
        ],
        if (!isSearching && !embedded)
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(
                  left: 15, right: 15, top: 15, bottom: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "pasaj.job_finder.nearby_listings".tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.siralaTapped(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_up_arrow_down,
                          size: 14,
                          color: controller.short.value != 0
                              ? Colors.pinkAccent
                              : Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.short.value == 0
                              ? "pasaj.common.sort".tr
                              : controller.short.value == 1
                                  ? "pasaj.job_finder.sort_high_salary".tr
                                  : controller.short.value == 2
                                      ? "pasaj.job_finder.sort_low_salary".tr
                                      : "pasaj.job_finder.sort_nearest".tr,
                          style: TextStyle(
                            color: controller.short.value != 0
                                ? Colors.pinkAccent
                                : Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(25, 25),
                      fixedSize: const Size(30, 30),
                    ),
                    onPressed: () => controller.filtreTapped(),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      color: controller.filtre.value
                          ? Colors.pinkAccent
                          : Colors.black,
                      size: 20,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(25, 25),
                      fixedSize: const Size(30, 30),
                    ),
                    onPressed: () {
                      controller.toggleListingSelection();
                    },
                    child: Icon(
                      controller.listingSelection.value == 0
                          ? CupertinoIcons.list_bullet
                          : CupertinoIcons.square_grid_2x2,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
