part of 'tests_grid_controller.dart';

extension TestsGridControllerActionsPart on TestsGridController {
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
                        'tests.report_title'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      secim.value = secim.value != 'yanlis_cevaplar'
                          ? 'yanlis_cevaplar'
                          : '';
                      Get.back();
                      modalSetState(() {});
                    },
                    child: SizedBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'tests.report_wrong_answers'.tr,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'MontserratMedium',
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
                                    color: secim.value == 'yanlis_cevaplar'
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
                          secim.value != 'yanlis_bolum' ? 'yanlis_bolum' : '';
                      Get.back();
                      modalSetState(() {});
                    },
                    child: SizedBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'tests.report_wrong_section'.tr,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'MontserratMedium',
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
                                    color: secim.value == 'yanlis_bolum'
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
                      secim.value = secim.value != 'spam' ? 'spam' : '';
                      Get.back();
                      modalSetState(() {});
                    },
                    child: SizedBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'report.reason.spam.title'.tr,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'MontserratMedium',
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
                                    color: secim.value == 'spam'
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
    if (model.userID == CurrentUserService.instance.effectiveUserId) {
      Get.bottomSheet(
        Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'tests.action_select'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'tests.action_select_body'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    _actionButton(
                      label: 'tests.delete_test'.tr,
                      color: Colors.red,
                      onTap: () => showDeleteConfirmation(context),
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      label: 'tests.edit_title'.tr,
                      color: Colors.purple,
                      onTap: () {
                        Get.back();
                        const EducationTestNavigationService()
                            .openCreateTest(model: model)
                            .then((_) => update());
                      },
                    ),
                    if (model.paylasilabilir) ...[
                      const SizedBox(height: 10),
                      _actionButton(
                        label: 'tests.copy_test_id'.tr,
                        color: Colors.green,
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: 'tests.share_test_id_text'.trParams({
                                'type': model.testTuru,
                                'id': model.docID,
                                'appStore': appStore.value,
                                'playStore': googlePlay.value,
                              }),
                            ),
                          );
                          Get.back();
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    _actionButton(
                      label: 'tests.solve_title'.tr,
                      color: Colors.indigo,
                      onTap: () {
                        Get.back();
                        const EducationTestNavigationService().openSolveTest(
                          testID: model.docID,
                          showSucces: showAlert,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      label: 'common.close'.tr,
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
      return;
    }

    const EducationTestNavigationService().openSolveTest(
      testID: model.docID,
      showSucces: showAlert,
    );
  }

  void showDeleteConfirmation(BuildContext context) {
    noYesAlert(
      title: 'tests.delete_test'.tr,
      message: 'tests.delete_confirm'.tr,
      cancelText: 'common.close'.tr,
      yesText: 'tests.delete_test'.tr,
      onYesPressed: () async {
        await _testRepository.deleteTest(model.docID);
        update();
      },
    );
  }

  void copyTestId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: model.docID));
    AppSnackbar('common.success'.tr, 'tests.id_copied'.tr);
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
                'tests.completed_title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'tests.completed_body'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
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
                    'common.close'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'MontserratBold',
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
              fontFamily: 'MontserratMedium',
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void navigateToProfile(BuildContext context) {
    if (model.userID != CurrentUserService.instance.effectiveUserId) {
      const ProfileNavigationService().openSocialProfile(model.userID);
      return;
    }
    const ProfileNavigationService().openMyProfile();
  }

  void navigateToTestSolve(BuildContext context) {
    const EducationTestNavigationService().openSolveTest(
      testID: model.docID,
      showSucces: showAlert,
    );
  }
}
