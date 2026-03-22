import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class CreateAnswerKeyController extends GetxController {
  static CreateAnswerKeyController ensure(
    Function onBack, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateAnswerKeyController(onBack),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateAnswerKeyController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateAnswerKeyController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateAnswerKeyController>(tag: tag);
  }

  final Function onBack;
  final nameController = TextEditingController();
  final selections = <String>["A"].obs;
  final selection = 5.obs;
  final selectedDateTime = DateTime.now().obs;
  final sinavSuresiCount = 30.obs;
  final showSinavSureleri = false.obs;
  final mainSelection = 0.obs;

  CreateAnswerKeyController(this.onBack);

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        selectedDateTime.value = fullDateTime;
      }
    }
  }

  void toggleSinavSureleri() {
    showSinavSureleri.value = !showSinavSureleri.value;
  }

  void selectSinavSuresi(int duration) {
    sinavSuresiCount.value = duration;
    showSinavSureleri.value = false;
  }

  void setSelection(int value) {
    selection.value = value;
  }

  void addSelection() {
    selections.add("");
  }

  void removeSelection(int index) {
    if (selections.length > 1) {
      selections.removeAt(index);
    }
  }

  void updateSelection(int index, String value) {
    selections[index] = value;
  }

  Future<void> saveForm(BuildContext context) async {
    final docID = DateTime.now().millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance.collection("optikForm").doc(docID).set({
      "max": selection.value,
      "cevaplar": selections.toList(),
      "name": nameController.text.isNotEmpty
          ? nameController.text
          : "answer_key.untitled_optical_form".tr,
      "userID": CurrentUserService.instance.effectiveUserId,
      "baslangic": selectedDateTime.value.millisecondsSinceEpoch,
      "bitis": selectedDateTime.value.millisecondsSinceEpoch +
          (60000 * sinavSuresiCount.value),
      "kisitlama": false,
    });

    onBack();
    Get.back();
  }
}
