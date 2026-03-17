import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultContent/booklet_result_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results_controller.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/ResultsAndAnswers/results_and_answers.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class MyBookletResults extends StatefulWidget {
  const MyBookletResults({super.key});

  @override
  State<MyBookletResults> createState() => _MyBookletResultsState();
}

class _MyBookletResultsState extends State<MyBookletResults> {
  final MyBookletResultsController controller =
      Get.put(MyBookletResultsController());
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildBooksEmpty() {
    return Container(
      color: Colors.white,
      child: const Padding(
        padding: EdgeInsets.only(top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.black,
                ),
                SizedBox(height: 7),
                Text(
                  "Her hangi kitapçık çözmedin",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookletPage() {
    if (controller.list.isNotEmpty) {
      return Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: controller.list.length,
          itemBuilder: (context, index) {
            final item = controller.list[index];
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 15 : 0),
              child: BookletResultContent(model: item),
            );
          },
        ),
      );
    }
    return _buildBooksEmpty();
  }

  Widget _buildOpticalPage() {
    if (controller.optikSonuclari.isNotEmpty) {
      return Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: controller.optikSonuclari.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Get.to(
                  () => ResultsAndAnswers(
                    model: controller.optikSonuclari[index],
                  ),
                );
              },
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.optikSonuclari[index].name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      8.ph,
                      Text(
                        formatTimestamp(
                          controller.optikSonuclari[index].baslangic.toInt(),
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return Container(
      color: Colors.white,
      child: const Padding(
        padding: EdgeInsets.only(top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.black,
                ),
                SizedBox(height: 7),
                Text(
                  "Her hangi optik form çözmedin",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BackButtons(text: "Sonuçlarım"),
            Obx(
              () => PageLineBar(
                barList: [
                  "Kitap (${controller.list.length})",
                  "Optik Form",
                ],
                pageName: "MyBookletResults",
                pageController: _pageController,
              ),
            ),
            Obx(
              () => controller.isLoading.value &&
                      controller.list.isEmpty &&
                      controller.optikSonuclari.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      ),
                    )
                  : Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          controller.setSelection(index);
                          if (Get.isRegistered<PageLineBarController>(
                            tag: "MyBookletResults",
                          )) {
                            Get.find<PageLineBarController>(
                              tag: "MyBookletResults",
                            ).selection.value = index;
                          }
                        },
                        children: [
                          _buildBookletPage(),
                          _buildOpticalPage(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
