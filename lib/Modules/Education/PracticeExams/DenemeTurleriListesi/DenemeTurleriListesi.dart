import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/DenemeGrid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeTurleriListesi/DenemeTurleriListesiController.dart';

class DenemeTurleriListesi extends StatelessWidget {
  final String sinavTuru;

  const DenemeTurleriListesi({super.key, required this.sinavTuru});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      DenemeTurleriListesiController(sinavTuru: sinavTuru),
    );

    Widget buildExamGrid() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5.0,
            mainAxisSpacing: 5.0,
            childAspectRatio: 2 / 4,
          ),
          itemCount: controller.list.length,
          itemBuilder: (context, index) {
            return DenemeGrid(
              model: controller.list[index],
              getData: controller.getData,
            );
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: sinavTuru),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 20),
                      )
                    : controller.isInitialized.value && controller.list.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "$sinavTuru türünde sınav bulunamadı. Lütfen yeni bir sınav oluşturun veya farklı bir sınav türü seçin.",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.white,
                            backgroundColor: Colors.black,
                            onRefresh: controller.getData,
                            child: ListView(children: [buildExamGrid()]),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
