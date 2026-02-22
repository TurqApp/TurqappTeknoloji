import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/CreateTest.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTests/MyTestsController.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/TestsGrid.dart';

class MyTests extends StatelessWidget {
  const MyTests({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyTestsController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              children: [
                BackButtons(text: "Testlerim"),
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: controller.getData,
                    child: Obx(
                      () => controller.isLoading.value
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 20,
                                color: Colors.black,
                              ),
                            )
                          : controller.list.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.black,
                                        size: 40,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Sonuç bulunamadı.\nDaha önce hiç test oluşturmadınız.",
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
                                  padding: const EdgeInsets.only(
                                    left: 15,
                                    right: 15,
                                  ),
                                  child: GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 5.0,
                                      mainAxisSpacing: 5.0,
                                      childAspectRatio: 1.85 / 3.6,
                                    ),
                                    itemCount: controller.list.length,
                                    itemBuilder: (context, index) {
                                      return TestsGrid(
                                        model: controller.list[index],
                                        update: controller.getData,
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Get.to(() => CreateTest());
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Obx(
                      () => controller.list.isEmpty
                          ? Transform.translate(
                              offset: const Offset(-20, -30),
                              child: Image.asset(
                                "assets/education/arrowdef.webp",
                                height: 80,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Container(
                      height: 60,
                      width: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
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
