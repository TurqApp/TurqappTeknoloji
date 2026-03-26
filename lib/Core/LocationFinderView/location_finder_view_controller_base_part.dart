part of 'location_finder_view_controller.dart';

abstract class _LocationFinderViewControllerBase extends GetxController {
  final Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final RxBool isDragging = false.obs;
  final RxString currentAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    (this as LocationFinderViewController)._handleLocationFinderOnInit();
  }

  @override
  void onClose() {
    (this as LocationFinderViewController)._handleLocationFinderOnClose();
    super.onClose();
  }
}
