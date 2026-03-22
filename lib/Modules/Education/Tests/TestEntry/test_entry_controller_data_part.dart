part of 'test_entry_controller.dart';

extension TestEntryControllerDataPart on TestEntryController {
  void _handleControllerInit() {
    focusNode.requestFocus();
  }

  void _handleControllerClose() {
    textController.dispose();
    focusNode.dispose();
  }

  void onTextChanged(String val) {
    if (val.length >= 10) {
      getTests(val);
    }
  }

  void onTextSubmitted(String val) {
    if (val.length >= 10) {
      getTests(val);
    }
  }

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

  String localizedTestType(String raw) => _helper.localizedTestType(raw);

  String localizedLessons(List<String> lessons) =>
      _helper.localizedLessons(lessons);
}
