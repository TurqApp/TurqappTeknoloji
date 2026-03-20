import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';

import '../JobContent/job_content.dart';
import 'my_job_ads_controller.dart';

class MyJobAds extends StatelessWidget {
  MyJobAds({super.key});
  final controller = Get.put(MyJobAdsController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [BackButtons(text: "pasaj.job_finder.my_ads".tr)],
              ),
            ),
            PageLineBar(
                barList: [
                  "pasaj.job_finder.published_tab".tr,
                  "pasaj.job_finder.expired_tab".tr,
                ],
                pageName: "MyJobAds",
                pageController: controller.pageController),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (v) {
                  Get.find<PageLineBarController>(tag: "MyJobAds")
                      .selection
                      .value = v;
                },
                children: [
                  Obx(() {
                    if (controller.isLoadingActive.value &&
                        controller.active.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      );
                    }
                    return controller.active.isNotEmpty
                        ? ListView.builder(
                            itemCount: controller.active.length,
                            itemBuilder: (context, index) {
                              final model = controller.active[index];
                              return Padding(
                                padding:
                                    EdgeInsets.only(top: index == 0 ? 7 : 0),
                                child: JobContent(
                                  key: ValueKey('myjob-active-${model.docID}'),
                                  model: model,
                                  isGrid: false,
                                ),
                              );
                            },
                          )
                        : EmptyRow(text: "pasaj.job_finder.no_my_ads".tr);
                  }),
                  Obx(() {
                    if (controller.isLoadingDeactive.value &&
                        controller.deactive.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      );
                    }
                    return controller.deactive.isNotEmpty
                        ? ListView.builder(
                            itemCount: controller.deactive.length,
                            itemBuilder: (context, index) {
                              final model = controller.deactive[index];
                              return Padding(
                                padding:
                                    EdgeInsets.only(top: index == 0 ? 7 : 0),
                                child: JobContent(
                                  key: ValueKey('myjob-ended-${model.docID}'),
                                  model: model,
                                  isGrid: false,
                                ),
                              );
                            },
                          )
                        : EmptyRow(text: "pasaj.job_finder.no_my_ads".tr);
                  })
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
