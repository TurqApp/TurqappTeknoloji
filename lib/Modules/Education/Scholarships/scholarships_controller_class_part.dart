part of 'scholarships_controller.dart';

class ScholarshipsController extends GetxController {
  static const String _listingSelectionPrefKeyPrefix =
      'scholarship_listing_selection';

  static ScholarshipsController ensure({bool permanent = false}) =>
      maybeFind() ?? Get.put(ScholarshipsController(), permanent: permanent);

  static ScholarshipsController? maybeFind() =>
      Get.isRegistered<ScholarshipsController>()
          ? Get.find<ScholarshipsController>()
          : null;

  final _state = _ScholarshipsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
