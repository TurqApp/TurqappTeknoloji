part of 'test_entry_controller.dart';

extension _TestEntryControllerActionsPart on TestEntryController {
  Future<void> getTests(String testID) async {
    isLoading.value = true;
    try {
      final data = await _testRepository.fetchRawById(
        testID,
        preferCache: true,
      );
      if (data != null) {
        model.value = TestsModel(
          userID: data['userID'] as String,
          timeStamp: data['timeStamp'] as String,
          aciklama: data['aciklama'] as String,
          dersler: List<String>.from(data['dersler'] ?? []),
          img: data['img'] as String,
          docID: testID,
          paylasilabilir: data['paylasilabilir'] as bool,
          testTuru: data['testTuru'] as String,
          taslak: data['taslak'] as bool,
        );
        closeKeyboard(Get.context!);
      } else {
        model.value = null;
      }
    } catch (_) {
      model.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
