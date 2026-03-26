part of 'test_entry_controller.dart';

TestEntryController? _maybeFindTestEntryController({String? tag}) {
  final isRegistered = Get.isRegistered<TestEntryController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TestEntryController>(tag: tag);
}

TestEntryController _ensureTestEntryController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindTestEntryController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TestEntryController(),
    tag: tag,
    permanent: permanent,
  );
}

extension TestEntryControllerFacadePart on TestEntryController {
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
