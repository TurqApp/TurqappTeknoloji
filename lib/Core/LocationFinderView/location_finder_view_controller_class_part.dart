part of 'location_finder_view_controller.dart';

class LocationFinderViewController extends GetxController {
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  RxBool isDragging = false.obs;
  RxString currentAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _handleLocationFinderOnInit();
  }

  @override
  void onClose() {
    _handleLocationFinderOnClose();
    super.onClose();
  }
}
