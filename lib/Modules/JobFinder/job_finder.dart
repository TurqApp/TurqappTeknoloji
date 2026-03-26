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
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';

import '../../Themes/app_assets.dart';

part 'job_finder_content_part.dart';
part 'job_finder_header_part.dart';

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

    return SearchResetOnPageReturnScope(
      onReset: () {
        controller.search.clear();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
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
      ),
    );
  }
}
