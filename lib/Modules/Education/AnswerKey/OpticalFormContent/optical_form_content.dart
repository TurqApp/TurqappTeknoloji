import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormContent/optical_form_content_controller.dart';

class OpticalFormContent extends StatelessWidget {
  final OpticalFormModel model;
  final Function() update;

  const OpticalFormContent({
    super.key,
    required this.model,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      OpticalFormContentController(model),
      tag: model.docID,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
      child: Dismissible(
        key: Key(model.docID),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          bool shouldDelete = false;
          await noYesAlert(
            title: "Silme İşlemi",
            message:
                "${model.name} adlı optik formu silmek istediğinizden emin misiniz?",
            onYesPressed: () {
              shouldDelete = true;
              controller
                  .deleteOpticalForm()
                  .then((_) => update()); // Call update after deletion
            },
            yesText: "Sil",
            cancelText: "İptal",
          );
          return shouldDelete;
        },
        dismissThresholds: const {
          DismissDirection.endToStart: 0.33,
        },
        child: GestureDetector(
          child: Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          model.name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                      Text(
                        model.bitis < DateTime.now().millisecondsSinceEpoch
                            ? "Sınav Bitti"
                            : model.baslangic.toInt() <
                                    DateTime.now().millisecondsSinceEpoch
                                ? "Sınav Başladı"
                                : "Sınav Başlamadı",
                        style: TextStyle(
                          color: model.bitis <
                                  DateTime.now().millisecondsSinceEpoch
                              ? Colors.red
                              : model.baslangic.toInt() <
                                      DateTime.now().millisecondsSinceEpoch
                                  ? Colors.green
                                  : Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Toplam ${model.cevaplar.length} Soru",
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      Obx(
                        () => Row(
                          children: [
                            Text(
                              "${controller.total.value} Kişi",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                            const Icon(
                              Icons.person,
                              color: Colors.pink,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.copyDocID();
                          AppSnackbar("Başarılı", "ID Kopyalandı");
                        },
                        child: Row(
                          children: [
                            Text(
                              "ID: ${model.docID}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.copy,
                                color: Colors.black, size: 15),
                          ],
                        ),
                      ),
                      Text(
                        timeAgo(int.parse(model.docID)),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
