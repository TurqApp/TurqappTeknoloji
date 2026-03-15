part of 'job_details.dart';

extension JobDetailsActionsPart on JobDetails {
  Widget _buildBottomActionSection(JobDetailsController controller) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (controller.model.value.userID ==
                (FirebaseAuth.instance.currentUser?.uid ?? ''))
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: controller.goToEdit,
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "İlanı Düzenle",
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
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F2F2F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Başvurular",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        noYesAlert(
                          title: "İlanı Yayından Kaldır",
                          message:
                              "Bu ilanı yayından kaldırmak istediğinizden emin misiniz?",
                          yesText: "Kaldır",
                          cancelText: "Vazgeç",
                          onYesPressed: () async {
                            try {
                              await controller.unpublishAd();
                              AppSnackbar(
                                "Başarılı",
                                "İlan yayından kaldırıldı.",
                              );
                            } catch (e) {
                              AppSnackbar(
                                "Hata",
                                "İlan kaldırılamadı: $e",
                                backgroundColor: Colors.red.withAlpha(40),
                              );
                            }
                          },
                        );
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "İlanı Yayından Kaldır",
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
                              "Bilgi",
                              "Bu ilana zaten başvuru yaptınız.",
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
                                    const Text(
                                      "Özgeçmiş Gerekli",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "İş başvurusu yapabilmek için özgeçmişinizi doldurmanız gerekiyor.",
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
                                          "Özgeçmiş Oluştur",
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
                                        child: const Text(
                                          "Vazgeç",
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
                            var isSubmitting = false;
                            Get.bottomSheet(
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Başvuru Gönder",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "Özgeçmişiniz hazır.\nBaşvurmak istediğinizden emin misiniz?",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        GestureDetector(
                                          onTap: isSubmitting
                                              ? null
                                              : () async {
                                                  Get.to(() => Cv());
                                                },
                                          child: Container(
                                            height: 50,
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                              color: Colors.blueAccent,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              "Özgeçmişi Düzenle",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: isSubmitting
                                                    ? null
                                                    : () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                child: Container(
                                                  height: 50,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withAlpha(50),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Text(
                                                    "Vazgeç",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratBold",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: isSubmitting
                                                    ? null
                                                    : () async {
                                                        setState(
                                                          () => isSubmitting =
                                                              true,
                                                        );
                                                        await controller
                                                            .toggleBasvuru(
                                                          model.docID,
                                                        );
                                                        if (controller
                                                            .basvuruldu.value) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          return;
                                                        }
                                                        setState(
                                                          () => isSubmitting =
                                                              false,
                                                        );
                                                      },
                                                child: Container(
                                                  height: 50,
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(12),
                                                    ),
                                                  ),
                                                  child: isSubmitting
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        )
                                                      : const Text(
                                                          "Başvur",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratBold",
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              isScrollControlled: true,
                            );
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
                                ? "Başvuru Yapıldı"
                                : "Başvur",
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
                              title: "Başvuru İptali",
                              message:
                                  "Başvurunuzu iptal etmek istediğinizden emin misiniz?",
                              cancelText: "Vazgeç",
                              yesText: "İptal Et",
                              onYesPressed: () async {
                                await controller.toggleBasvuru(model.docID);
                                AppSnackbar(
                                    "Bilgi", "Başvurunuz iptal edildi.");
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
                              "Başvuru İptal",
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
