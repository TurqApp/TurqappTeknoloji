part of 'optical_form_entry_controller_library.dart';

extension OpticalFormEntryControllerActionsPart on OpticalFormEntryController {
  Future<void> showAlert() async {
    final currentModel = model.value;
    if (currentModel != null) {
      try {
        final userAnswers = await _opticalFormRepository.fetchUserAnswers(
          currentModel.docID,
          CurrentUserService.instance.effectiveUserId,
          forceRefresh: true,
        );
        final answerKey = currentModel.cevaplar;

        int dogru = 0;
        int yanlis = 0;
        int bos = 0;

        final len = userAnswers.length < answerKey.length
            ? userAnswers.length
            : answerKey.length;
        for (var i = 0; i < len; i++) {
          final selected = userAnswers[i];
          final correct = answerKey[i];
          if (selected.isEmpty) {
            bos++;
          } else if (selected == correct) {
            dogru++;
          } else {
            yanlis++;
          }
        }
        if (answerKey.length > userAnswers.length) {
          bos += answerKey.length - userAnswers.length;
        }

        final net = dogru - (yanlis * 0.25);
        showAlertDialog(
          'tests.completed_title'.tr,
          'tests.result_breakdown'.trParams({
            'correct': '$dogru',
            'wrong': '$yanlis',
            'blank': '$bos',
            'net': net.toStringAsFixed(2),
          }),
        );
      } catch (_) {
        showAlertDialog(
          'tests.completed_title'.tr,
          'tests.result_unavailable'.tr,
        );
      }
    } else {
      showAlertDialog(
        'tests.completed_title'.tr,
        'tests.result_unavailable'.tr,
      );
    }
    model.value = null;
    search.text = '';
    searchText.value = '';
  }

  void handleExamTap(BuildContext context) {
    if (model.value!.baslangic.toInt() >
        DateTime.now().millisecondsSinceEpoch) {
      showAlertDialog(
        'answer_key.exam_not_started_title'.tr,
        'answer_key.exam_not_started_body'.tr,
      );
    } else {
      Get.to(
        () => OpticalPreview(
          model: model.value!,
          update: showAlert,
        ),
      );
    }
  }

  void copyDocID() {
    Clipboard.setData(ClipboardData(text: model.value!.docID));
  }

  void showAlertDialog(String title, String desc) {
    infoAlert(
      title: title,
      message: desc,
    );
  }
}
