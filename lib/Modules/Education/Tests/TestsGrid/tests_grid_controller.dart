import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_view.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

class TestsGridController extends GetxController {
  final TestsModel model;
  final Function? onUpdate;

  final fullName = ''.obs;
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final secim = ''.obs;
  final totalYanit = 0.obs;
  final isFavorite = false.obs;
  final appStore = ''.obs;
  final googlePlay = ''.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  TestsGridController(this.model, this.onUpdate) {
    _initialize();
  }

  void _initialize() {
    checkIfFavorite();
    getUygulamaLinks();
    getUserData();
    getTotalYanit();
  }

  void getUserData() async {
    final user = await UserRepository.ensure().getUser(
      model.userID,
      preferCache: true,
      cacheOnly: false,
    );
    fullName.value = user?.displayName ?? '';
    avatarUrl.value = user?.avatarUrl ?? '';
    nickname.value = user?.preferredName ?? '';
  }

  void getTotalYanit() async {
    final snapshot = await _testRepository.fetchAnswers(
      model.docID,
      preferCache: true,
    );
    totalYanit.value = snapshot.length;
  }

  void getUygulamaLinks() async {
    final data = await ConfigRepository.ensure().getLegacyConfigDoc(
          collection: "Yönetim",
          docId: "Genel",
          preferCache: true,
          ttl: const Duration(hours: 12),
        ) ??
        const <String, dynamic>{};
    appStore.value = (data["appStore"] ?? "").toString();
    googlePlay.value = (data["googlePlay"] ?? "").toString();
  }

  void checkIfFavorite() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final data = await _testRepository.fetchRawById(
      model.docID,
      preferCache: true,
    );

    if (data != null) {
      final favorites = List<String>.from(data['favoriler'] ?? []);
      isFavorite.value = favorites.contains(userId);
    }
  }

  void toggleFavorite() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    isFavorite.value = await _testRepository.toggleFavorite(
      model.docID,
      userId: userId,
    );
  }

  void showReportModal(BuildContext context) {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return FractionallySizedBox(
            heightFactor: 0.24,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "tests.report_title".tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      secim.value = secim.value != "yanlis_cevaplar"
                          ? "yanlis_cevaplar"
                          : "";
                      Get.back();
                      modalSetState(() {});
                    },
                    child: SizedBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              "tests.report_wrong_answers".tr,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Obx(
                            () => Container(
                              width: 25,
                              height: 25,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: secim.value == "yanlis_cevaplar"
                                        ? Colors.indigo
                                        : Colors.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      secim.value =
                          secim.value != "yanlis_bolum" ? "yanlis_bolum" : "";
                      Get.back();
                      modalSetState(() {});
                    },
                    child: SizedBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              "tests.report_wrong_section".tr,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Obx(
                            () => Container(
                              width: 25,
                              height: 25,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: secim.value == "yanlis_bolum"
                                        ? Colors.indigo
                                        : Colors.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      secim.value = secim.value != "Spam" ? "Spam" : "";
                      Get.back();
                      modalSetState(() {});
                    },
                    child: SizedBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              "Spam",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Obx(
                            () => Container(
                              width: 25,
                              height: 25,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: secim.value == "Spam"
                                        ? Colors.indigo
                                        : Colors.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      isScrollControlled: true,
    );
  }

  void handleTestAction(BuildContext context) {
    if (model.userID == FirebaseAuth.instance.currentUser!.uid) {
      Get.bottomSheet(
        Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "tests.action_select".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: "MontserratBold",
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "tests.action_select_body".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: "MontserratMedium",
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    _actionButton(
                      label: "tests.delete_test".tr,
                      color: Colors.red,
                      onTap: () => showDeleteConfirmation(context),
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      label: "tests.edit_title".tr,
                      color: Colors.purple,
                      onTap: () {
                        Get.back();
                        Get.to(() => CreateTest(model: model))
                            ?.then((v) => update.call());
                      },
                    ),
                    if (model.paylasilabilir) ...[
                      const SizedBox(height: 10),
                      _actionButton(
                        label: "tests.copy_test_id".tr,
                        color: Colors.green,
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: "tests.share_test_id_text".trParams({
                                "type": model.testTuru,
                                "id": model.docID,
                                "appStore": appStore.value,
                                "playStore": googlePlay.value,
                              }),
                            ),
                          );
                          Get.back();
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    _actionButton(
                      label: "tests.solve_title".tr,
                      color: Colors.indigo,
                      onTap: () {
                        Get.back();
                        Get.to(() => SolveTest(
                            testID: model.docID, showSucces: showAlert));
                      },
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      label: "common.close".tr,
                      color: Colors.black,
                      onTap: Get.back,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      );
    } else {
      Get.to(() => SolveTest(testID: model.docID, showSucces: showAlert));
    }
  }

  void showDeleteConfirmation(BuildContext context) {
    noYesAlert(
      title: "tests.delete_test".tr,
      message: "tests.delete_confirm".tr,
      cancelText: "common.close".tr,
      yesText: "tests.delete_test".tr,
      onYesPressed: () {
        FirebaseFirestore.instance
            .collection("Testler")
            .doc(model.docID)
            .delete();
        update.call();
      },
    );
  }

  void copyTestId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: model.docID));
    AppSnackbar("common.success".tr, "tests.id_copied".tr);
  }

  void showAlert() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "tests.completed_title".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "tests.completed_body".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: Get.back,
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "common.close".tr,
                    style: TextStyle(
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
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: "MontserratMedium",
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void navigateToProfile(BuildContext context) {
    if (model.userID != FirebaseAuth.instance.currentUser!.uid) {
      Get.to(() => SocialProfile(userID: model.userID));
    } else {
      Get.to(() => ProfileView());
    }
  }

  void navigateToTestSolve(BuildContext context) {
    Get.to(() => SolveTest(testID: model.docID, showSucces: showAlert));
  }
}
