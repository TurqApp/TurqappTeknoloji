import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content_controller.dart';

class CreateTestQuestionContent extends StatelessWidget {
  final TestReadinessModel model;
  final String testID;
  final int index;

  const CreateTestQuestionContent({
    super.key,
    required this.model,
    required this.testID,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CreateTestQuestionContentController(
        model: model,
        testID: testID,
        index: index,
      ),
      tag: 'question_${model.docID}',
    );

    return Obx(
      () => controller.isInvalid.value
          ? Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.info_outline, color: Colors.black, size: 40),
                  SizedBox(height: 10),
                  Text(
                    "Soru içeriği yüklenemedi.\nLütfen tekrar deneyin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.only(
                bottom: 20,
                top: index == 0 ? 20 : 0,
                left: 20,
                right: 20,
              ),
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        controller.isLoading.value
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 20,
                                  color: Colors.black,
                                ),
                              )
                            : controller.selectedImage.value != null
                                ? GestureDetector(
                                    child: Image.file(
                                      controller.selectedImage.value!,
                                    ),
                                    onTap: () => print(controller.model.img),
                                  )
                                : controller.model.img.isEmpty
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 20),
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 20),
                                            Image.asset(
                                              "assets/createsoru.webp",
                                              height: 180,
                                            ),
                                            const SizedBox(height: 15),
                                            const Text(
                                              "Çek ve Yükle",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 25,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 30,
                                              ),
                                              child: Text(
                                                "Sorunun fotoğrafını çek, doğru cevabı seç ve kolayca hazırla!",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 20,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 30,
                                                right: 30,
                                                top: 20,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: controller
                                                          .pickImageFromGallery,
                                                      child: Container(
                                                        height: 40,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.pink,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(12),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          "Galeriden Seç",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratMedium",
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: controller
                                                          .pickImageFromGallery,
                                                      child: Container(
                                                        height: 40,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.indigo,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(12),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          "Kameradan Yükle",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontFamily:
                                                                "MontserratBold",
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
                                      )
                                    : Image.network(
                                        controller.model.img,
                                        key: ValueKey(controller.model.img),
                                      ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              controller.model.max.toInt(),
                              (i) {
                                String choice = ["A", "B", "C", "D", "E"][i];
                                return GestureDetector(
                                  onTap: () =>
                                      controller.setCorrectAnswer(choice),
                                  child: Obx(
                                    () => Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      height: 40,
                                      width: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: controller.model.dogruCevap ==
                                                choice
                                            ? Colors.green
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          50,
                                        ),
                                        border: Border.all(
                                          color: controller.model.dogruCevap ==
                                                  choice
                                              ? Colors.green
                                              : Colors.black,
                                        ),
                                      ),
                                      child: Text(
                                        choice,
                                        style: TextStyle(
                                          color: controller.model.dogruCevap ==
                                                  choice
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-15, -15),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.indigo,
                      ),
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
