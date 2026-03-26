part of 'test_entry_controller.dart';

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

  Future<void> getTests(String testID) =>
      _TestEntryControllerActionsPart(this).getTests(testID);

  String localizedTestType(String raw) => _helper.localizedTestType(raw);

  String localizedLessons(List<String> lessons) =>
      _helper.localizedLessons(lessons);
}
