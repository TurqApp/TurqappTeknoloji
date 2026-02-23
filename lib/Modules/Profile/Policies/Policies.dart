import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Profile/Policies/policies_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class Policies extends StatelessWidget {
  Policies({super.key});
  final controller = Get.put(PoliciesController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Politikalar"),
            PageLineBar(
                barList: ["Gizlilik", "Kullanıcı", "Reklam"],
                pageName: "Policies",
                pageController: controller.pageController),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (v) {
                  Get.find<PageLineBarController>(tag: "Policies")
                      .selection
                      .value = v;
                },
                children: [
                  Obx(() {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.privacyPolicy.value,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "Montserrat"),
                            ),
                            12.ph,
                          ],
                        ),
                      ),
                    );
                  }),
                  Obx(() {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.eula.value,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium"),
                            ),
                            SizedBox(
                              height: 12,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Obx(() {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.ad.value,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium"),
                            ),
                            SizedBox(
                              height: 12,
                            ),
                          ],
                        ),
                      ),
                    );
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
