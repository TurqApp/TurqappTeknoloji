part of 'location_finder_view_controller.dart';

class LocationFinderViewController extends GetxController {
  static LocationFinderViewController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      LocationFinderViewController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static LocationFinderViewController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<LocationFinderViewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<LocationFinderViewController>(tag: tag);
  }

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
