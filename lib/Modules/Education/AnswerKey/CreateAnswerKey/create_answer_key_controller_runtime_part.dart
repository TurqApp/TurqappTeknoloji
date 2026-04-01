part of 'create_answer_key_controller.dart';

void _disposeCreateAnswerKeyController(CreateAnswerKeyController controller) {
  controller.nameController.dispose();
}

Future<void> _selectCreateAnswerKeyDateTime(
  CreateAnswerKeyController controller,
  BuildContext context,
) async {
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
      controller.selectedDateTime.value = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }
  }
}

void _selectCreateAnswerKeyDuration(
  CreateAnswerKeyController controller,
  int duration,
) {
  controller.sinavSuresiCount.value = duration;
  controller.showSinavSureleri.value = false;
}

void _removeCreateAnswerKeySelection(
  CreateAnswerKeyController controller,
  int index,
) {
  if (controller.selections.length > 1) {
    controller.selections.removeAt(index);
  }
}

Future<void> _saveCreateAnswerKeyForm(
  CreateAnswerKeyController controller,
) async {
  if (!await TextModerationService.ensureAllowed(
      [controller.nameController.text])) {
    return;
  }
  final docID = DateTime.now().millisecondsSinceEpoch.toString();

  await FirebaseFirestore.instance.collection('optikForm').doc(docID).set({
    'max': controller.selection.value,
    'cevaplar': controller.selections.toList(),
    'name': controller.nameController.text.isNotEmpty
        ? controller.nameController.text
        : 'answer_key.untitled_optical_form'.tr,
    'userID': CurrentUserService.instance.effectiveUserId,
    'baslangic': controller.selectedDateTime.value.millisecondsSinceEpoch,
    'bitis': controller.selectedDateTime.value.millisecondsSinceEpoch +
        (60000 * controller.sinavSuresiCount.value),
    'kisitlama': false,
  });

  controller.onBack();
  Get.back();
}
