import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test.dart';

part 'test_entry_controller_fields_part.dart';
part 'test_entry_controller_runtime_part.dart';

class TestEntryController extends GetxController {
  static TestEntryController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestEntryController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestEntryController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TestEntryController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestEntryController>(tag: tag);
  }

  final _state = _TestEntryControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleTestEntryOnInit();
  }

  @override
  void onClose() {
    _handleTestEntryOnClose();
    super.onClose();
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
