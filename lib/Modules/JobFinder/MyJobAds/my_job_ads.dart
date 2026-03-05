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
                children: [BackButtons(text: "İlanlarım")],
              ),
            ),
            PageLineBar(
                barList: ["Yayında", "Süresi Doldu"],
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
                        : EmptyRow(text: "İlan Bulunamadı");
                  }),
                  Obx(() {
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
                        : EmptyRow(text: "İlan Bulunamadı");
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
