part of 'job_details.dart';

extension JobDetailsActionsPart on JobDetails {
  Widget _buildBottomActionSection(JobDetailsController controller) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (controller.model.value.userID == _currentUid)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: controller.goToEdit,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "pasaj.job_finder.edit_listing".tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: controller.goToApplicationReview,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black12,
                            ),
                          ),
                          child: Text(
                            "pasaj.job_finder.applications".tr,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          noYesAlert(
                            title: "pasaj.job_finder.unpublish_title".tr,
                            message: "pasaj.job_finder.unpublish_body".tr,
                            yesText: "common.remove".tr,
                            cancelText: "common.cancel".tr,
                            onYesPressed: () async {
                              try {
                                await controller.unpublishAd();
                                AppSnackbar(
                                  "common.success".tr,
                                  "pasaj.job_finder.unpublished".tr,
                                );
                              } catch (e) {
                                AppSnackbar(
                                  "common.error".tr,
                                  "pasaj.job_finder.unpublish_failed"
                                      .trParams({'error': '$e'}),
                                  backgroundColor: Colors.red.withAlpha(40),
                                );
                              }
                            },
                          );
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE45858),
                            ),
                          ),
                          child: Text(
                            "common.remove".tr,
                            style: TextStyle(
                              color: Color(0xFFE45858),
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // CV kontrolü burada yapılıyor
                          await controller.cvCheck();
                          if (controller.basvuruldu.value) {
                            AppSnackbar(
                              "common.info".tr,
                              "pasaj.job_finder.already_applied".tr,
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.grey.withAlpha(50),
                              colorText: Colors.black,
                              duration: Duration(seconds: 3),
                            );
                          } else if (!controller.cvVar.value) {
                            Get.bottomSheet(
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "pasaj.job_finder.cv_required".tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "pasaj.job_finder.cv_required_body".tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    GestureDetector(
                                      onTap: () async {
                                        Get.to(() => Cv());
                                      },
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12)),
                                        ),
                                        child: Text(
                                          "pasaj.job_finder.create_cv".tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        Get.back(); // Vazgeç
                                      },
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(50),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "common.cancel".tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isScrollControlled: true,
                            );
                          } else {
                            await controller.toggleBasvuru(model.docID);
                          }
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.basvuruldu.value
                                ? Colors.grey.withAlpha(50)
                                : Colors.black,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            border: Border.all(
                              color: controller.basvuruldu.value
                                  ? Colors.grey.withAlpha(50)
                                  : Colors.black,
                            ),
                          ),
                          child: Text(
                            controller.basvuruldu.value
                                ? "pasaj.job_finder.applied".tr
                                : "pasaj.job_finder.apply".tr,
                            style: TextStyle(
                              color: controller.basvuruldu.value
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (controller.basvuruldu.value) const SizedBox(width: 12),
                    if (controller.basvuruldu.value)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            noYesAlert(
                              title:
                                  "pasaj.job_finder.application_cancel_title".tr,
                              message:
                                  "pasaj.job_finder.application_cancel_body".tr,
                              cancelText: "common.cancel".tr,
                              yesText: "common.remove".tr,
                              onYesPressed: () async {
                                await controller.toggleBasvuru(model.docID);
                                AppSnackbar(
                                  "common.info".tr,
                                  "pasaj.job_finder.application_cancelled".tr,
                                );
                              },
                            );
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              "pasaj.job_finder.cancel_application".tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
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
      );
    });
  }
}
