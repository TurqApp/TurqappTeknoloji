part of 'scholarships_controller.dart';

class ScholarshipsController extends GetxController {
  static const String _listingSelectionPrefKeyPrefix =
      'scholarship_listing_selection';

  static ScholarshipsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ScholarshipsController(), permanent: permanent);
  }

  static ScholarshipsController? maybeFind() {
    final isRegistered = Get.isRegistered<ScholarshipsController>();
    if (!isRegistered) return null;
    return Get.find<ScholarshipsController>();
  }

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
