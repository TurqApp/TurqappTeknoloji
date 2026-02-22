import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGecmisSonucContent/DenemeGecmisSonucContent.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/SinavSonuclarimController.dart';

class SinavSonuclarim extends StatelessWidget {
  const SinavSonuclarim({super.key});

  @override
  Widget build(BuildContext context) {
    final SinavSonuclarimController controller = Get.put(
      SinavSonuclarimController(),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Deneme Sonuçlarım"),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CupertinoActivityIndicator(radius: 20),
                  );
                }
                if (controller.list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Henüz Sınava Girmediniz",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: "MontserratBold",
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Henüz herhangi bir deneme sınavına katılmadınız. Sınavlara katıldığınızda sonuçlarınız burada görünecektir.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontFamily: "MontserratMedium",
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  onRefresh: controller.findAndGetSinavlar,
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      controller: controller.scrollController,
                      itemCount: controller.list.length,
                      itemBuilder: (context, index) {
                        return DenemeGecmisSonucContent(
                          index: index,
                          model: controller.list[index],
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
