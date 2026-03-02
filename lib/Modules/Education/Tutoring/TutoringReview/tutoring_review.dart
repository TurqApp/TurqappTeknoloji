import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail_controller.dart';

void showTutoringReviewBottomSheet({
  required String docID,
  required TutoringDetailController controller,
}) {
  final selectedRating = 0.obs;
  final commentController = TextEditingController();
  final isSubmitting = false.obs;

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Değerlendirme Yap",
            style: TextStyle(
              fontFamily: "MontserratBold",
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Star rating
          Center(
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        selectedRating.value = index + 1;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < selectedRating.value
                              ? Icons.star
                              : Icons.star_border,
                          size: 40,
                          color: index < selectedRating.value
                              ? Colors.amber
                              : Colors.grey,
                        ),
                      ),
                    );
                  }),
                )),
          ),
          const SizedBox(height: 16),
          // Comment field
          TextField(
            controller: commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Yorumunuzu yazın (opsiyonel)",
              hintStyle: const TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 14,
                color: Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
            style: const TextStyle(
              fontFamily: "MontserratMedium",
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting.value
                      ? null
                      : () async {
                          if (selectedRating.value == 0) {
                            AppSnackbar(
                                "Hata", "Lütfen bir puan seçin.");
                            return;
                          }
                          isSubmitting.value = true;
                          await controller.submitReview(
                            docID,
                            selectedRating.value,
                            commentController.text.trim(),
                          );
                          isSubmitting.value = false;
                          Get.back();
                          AppSnackbar("Başarılı",
                              "Değerlendirmeniz kaydedildi.");
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          "Gönder",
                          style: TextStyle(
                            fontFamily: "MontserratBold",
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              )),
          const SizedBox(height: 10),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
