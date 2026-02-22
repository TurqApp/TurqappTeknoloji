import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Models/Education/TestsModel.dart';
import 'package:turqappv2/Modules/Education/Tests/MyPastTestResultsPreview.dart/MyPastTestResultsPreviewController.dart';

class MyPastTestResultsPreview extends StatelessWidget {
  final TestsModel model;

  const MyPastTestResultsPreview({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyPastTestResultsPreviewController(model));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Sonuçlar"),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : controller.soruList.isEmpty || controller.yanitlar.isEmpty
                        ? EmptyRow(
                            text:
                                "Sonuç bulunamadı.\nBu test için yanıt veya soru verisi mevcut değil.")
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.green,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.dogruSayisi.value
                                                  .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Doğru",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.red,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.yanlisSayisi.value
                                                  .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Yanlış",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.orange,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              controller.bosSayisi.value
                                                  .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Boş",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        color: Colors.indigo,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${controller.totalPuan.value.toStringAsFixed(0)}/100",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Puan",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                for (var index = 0;
                                    index < controller.soruList.length;
                                    index++)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: Offset(4, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 15,
                                                right: 15,
                                                top: 15,
                                              ),
                                              child: Text(
                                                "${index + 1}. Soru",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 20,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 20,
                                          ),
                                          child: Image.network(
                                            controller.soruList[index].img,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        buildChoices(controller, index),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChoices(
    MyPastTestResultsPreviewController controller,
    int index,
  ) {
    return Container(
      height: 50,
      color: Colors.pink.withOpacity(0.2),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var choice in ['A', 'B', 'C', 'D', 'E'])
              Stack(
                children: [
                  if (choice == controller.soruList[index].dogruCevap)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.determineChoiceColor(index, choice),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        color: controller.determineChoiceTextColor(
                          index,
                          choice,
                        ),
                        fontSize: 20,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
