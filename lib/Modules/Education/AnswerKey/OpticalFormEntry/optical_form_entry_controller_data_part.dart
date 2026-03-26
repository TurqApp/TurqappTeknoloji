part of 'optical_form_entry_controller_library.dart';

extension OpticalFormEntryControllerDataPart on OpticalFormEntryController {
  void _handleControllerInit() {
    search.addListener(() {
      searchText.value = search.text;
    });
  }

  void _handleControllerClose() {
    search.dispose();
    focusNode.dispose();
  }

  Future<void> searchDocID() async {
    final opticalForm = await _opticalFormRepository.fetchById(search.text);
    if (opticalForm == null) return;

    final bitis = opticalForm.bitis;
    final baslangic = opticalForm.baslangic;
    final userID = opticalForm.userID;

    if (bitis.toInt() > DateTime.now().millisecondsSinceEpoch) {
      focusNode.unfocus();
      model.value = OpticalFormModel(
        docID: opticalForm.docID,
        name: opticalForm.name,
        cevaplar: opticalForm.cevaplar,
        max: opticalForm.max,
        userID: opticalForm.userID,
        baslangic: baslangic,
        bitis: bitis,
        kisitlama: opticalForm.kisitlama,
      );
      await getUserData(userID);
      return;
    }

    focusNode.unfocus();
    showAlertDialog(
      'answer_key.exam_expired_title'.tr,
      'answer_key.exam_expired_body'.tr,
    );
    model.value = null;
  }

  Future<void> getUserData(String userID) async {
    final data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    fullName.value = data?.displayName.trim() ?? '';
    avatarUrl.value = data?.avatarUrl ?? '';
  }
}
