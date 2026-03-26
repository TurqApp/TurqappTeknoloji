part of 'flood_listing_controller.dart';

class FloodListingController extends GetxController {
  final _state = _FloodListingControllerState();

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
