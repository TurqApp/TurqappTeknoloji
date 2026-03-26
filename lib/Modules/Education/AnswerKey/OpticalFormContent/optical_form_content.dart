import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormContent/optical_form_content_controller.dart';

class OpticalFormContent extends StatefulWidget {
  final OpticalFormModel model;
  final Function() update;

  const OpticalFormContent({
    super.key,
    required this.model,
    required this.update,
  });

  @override
  State<OpticalFormContent> createState() => _OpticalFormContentState();
}

class _OpticalFormContentState extends State<OpticalFormContent> {
  late final OpticalFormContentController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  OpticalFormModel get model => widget.model;
  Function() get update => widget.update;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'optical_form_content_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindOpticalFormContentController(tag: _controllerTag) == null;
    controller = ensureOpticalFormContentController(
      widget.model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    final registeredController = maybeFindOpticalFormContentController(
      tag: _controllerTag,
    );
    if (_ownsController && identical(registeredController, controller)) {
      Get.delete<OpticalFormContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            title: "answer_key.delete_operation".tr,
            message: "answer_key.delete_optical_confirm"
                .trParams({'name': model.name}),
            onYesPressed: () {
              shouldDelete = true;
              controller
                  .deleteOpticalForm()
                  .then((_) => update()); // Call update after deletion
            },
            yesText: "common.delete".tr,
            cancelText: "common.cancel".tr,
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
                            ? "practice.finished_short".tr
                            : model.baslangic.toInt() <
                                    DateTime.now().millisecondsSinceEpoch
                                ? "practice.started".tr
                                : "practice.not_started".tr,
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
                        "answer_key.total_questions"
                            .trParams({'count': '${model.cevaplar.length}'}),
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
                              "answer_key.participant_count".trParams(
                                  {'count': '${controller.total.value}'}),
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
                          AppSnackbar(
                            "common.success".tr,
                            "answer_key.id_copied".tr,
                          );
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
