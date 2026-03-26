part of 'optical_preview_controller_library.dart';

void _initializeOpticalPreviewController(OpticalPreviewController controller) {
  controller.cevaplar.value = List.generate(
    controller.model.cevaplar.length,
    (_) => '',
  );
  _initializeOpticalPreviewAnswers(controller);
  _checkOpticalPreviewInternet(controller);
}

void _disposeOpticalPreviewController(OpticalPreviewController controller) {
  controller._connectivitySubscription?.cancel();
  controller.fullName.dispose();
  controller.ogrenciNo.dispose();
}

void _checkOpticalPreviewInternet(OpticalPreviewController controller) {
  controller._connectivitySubscription =
      Connectivity().onConnectivityChanged.listen((results) {
    controller.isConnected.value =
        results.any((r) => r != ConnectivityResult.none);
  });
}

void _saveOpticalPreviewData(OpticalPreviewController controller) {
  controller._opticalFormRepository
      .saveUserAnswers(
        controller.model.docID,
        CurrentUserService.instance.effectiveUserId,
        answers: controller.cevaplar.toList(growable: false),
        ogrenciNo: controller.ogrenciNo.text,
        fullName: controller.fullName.text,
      )
      .then((_) => Get.back());
}

void _initializeOpticalPreviewAnswers(OpticalPreviewController controller) {
  controller._opticalFormRepository.initializeUserAnswers(
    controller.model.docID,
    CurrentUserService.instance.effectiveUserId,
    controller.model.cevaplar.length,
  );
}

void _toggleOpticalPreviewAnswer(
  OpticalPreviewController controller,
  int index,
  String item,
) {
  if (controller.cevaplar[index] == item) {
    controller.cevaplar[index] = '';
  } else {
    controller.cevaplar[index] = item;
  }
}

void _handleOpticalPreviewFinish(OpticalPreviewController controller) {
  if (controller.isConnected.value) {
    controller.setData();
  } else {
    _showOpticalPreviewAlert(
      'answer_key.turn_on_internet_title'.tr,
      'answer_key.turn_on_internet_body'.tr,
    );
  }
}

void _showOpticalPreviewAlert(String title, String desc) {
  infoAlert(
    title: title,
    message: desc,
  );
}
