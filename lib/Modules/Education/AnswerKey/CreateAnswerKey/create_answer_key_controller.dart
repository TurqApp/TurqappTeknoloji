import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'create_answer_key_controller_runtime_part.dart';

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
    _disposeCreateAnswerKeyController(this);
    super.onClose();
  }

  Future<void> selectDateTime(BuildContext context) =>
      _selectCreateAnswerKeyDateTime(this, context);

  void toggleSinavSureleri() {
    showSinavSureleri.value = !showSinavSureleri.value;
  }

  void selectSinavSuresi(int duration) =>
      _selectCreateAnswerKeyDuration(this, duration);

  void setSelection(int value) {
    selection.value = value;
  }

  void addSelection() {
    selections.add("");
  }

  void removeSelection(int index) =>
      _removeCreateAnswerKeySelection(this, index);

  void updateSelection(int index, String value) {
    selections[index] = value;
  }

  Future<void> saveForm(BuildContext context) => _saveCreateAnswerKeyForm(this);
}
