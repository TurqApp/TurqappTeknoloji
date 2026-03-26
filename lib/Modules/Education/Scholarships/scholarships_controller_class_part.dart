part of 'scholarships_controller.dart';

class ScholarshipsController extends GetxController {
  static const String _listingSelectionPrefKeyPrefix =
      'scholarship_listing_selection';

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
