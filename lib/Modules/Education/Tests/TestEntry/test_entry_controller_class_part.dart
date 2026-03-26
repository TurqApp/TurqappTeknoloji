part of 'test_entry_controller.dart';

class TestEntryController extends GetxController {
  static TestEntryController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureTestEntryController(
        tag: tag,
        permanent: permanent,
      );

  static TestEntryController? maybeFind({String? tag}) =>
      _maybeFindTestEntryController(tag: tag);

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
}
