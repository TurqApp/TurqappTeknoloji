import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams_controller.dart';

class MyPracticeExams extends StatelessWidget {
  const MyPracticeExams({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final MyPracticeExamsController controller =
        Get.put(MyPracticeExamsController());

    if (uid.isEmpty) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: const [
              BackButtons(text: "Yayınladıklarım"),
              Expanded(
                child: Center(
                  child: Text(
                    "Kullanıcı oturumu bulunamadı.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BackButtons(text: "Yayınladıklarım"),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CupertinoActivityIndicator(),
                  );
                }

                if (controller.exams.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Henüz yayınladığınız bir online sınav yok.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  onRefresh: () => controller.fetchExams(forceRefresh: true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 0.52,
                      ),
                      itemCount: controller.exams.length,
                      itemBuilder: (context, index) {
                        return DenemeGrid(
                          model: controller.exams[index],
                          getData: () {},
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
