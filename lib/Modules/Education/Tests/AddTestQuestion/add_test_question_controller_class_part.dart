part of 'add_test_question_controller.dart';

class AddTestQuestionController extends GetxController {
  static AddTestQuestionController ensure({
    required List<TestReadinessModel> initialSoruList,
    required String testID,
    required String testTuru,
    required Function onUpdate,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AddTestQuestionController(
        initialSoruList: initialSoruList,
        testID: testID,
        testTuru: testTuru,
        onUpdate: onUpdate,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static AddTestQuestionController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AddTestQuestionController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AddTestQuestionController>(tag: tag);
  }

  final _AddTestQuestionControllerState _state;

  AddTestQuestionController({
    required List<TestReadinessModel> initialSoruList,
    required String testID,
    required String testTuru,
    required Function onUpdate,
  }) : _state = _AddTestQuestionControllerState(
          initialSoruList: initialSoruList,
          testID: testID,
          testTuru: testTuru,
          onUpdate: onUpdate,
        );

  @override
  void onInit() {
    super.onInit();
    soruList.assignAll(initialSoruList);
    getSorular();
  }
}
