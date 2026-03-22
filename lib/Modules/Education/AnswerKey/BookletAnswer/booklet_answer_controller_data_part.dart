part of 'booklet_answer_controller.dart';

extension BookletAnswerControllerDataPart on BookletAnswerController {
  void _handleControllerInit() {
    cevaplar.assignAll(List.filled(model.dogruCevaplar.length, ''));
    fetchAds();
  }

  Future<void> fetchAds() async {
    try {
      final doc = await _configRepository.getLegacyConfigDoc(
        collection: 'Yönetim',
        docId: 'Genel',
      );
      iosList.value = (doc?['iosFullReklamlar'] ?? '').toString();
      androidList.value = (doc?['androidFullReklamlar'] ?? '').toString();
      runAds();
    } catch (_) {}
  }

  void runAds() {
    final adUnitId = Platform.isIOS ? iosList.value : androidList.value;
    if (adUnitId.isNotEmpty) {}
  }
}
