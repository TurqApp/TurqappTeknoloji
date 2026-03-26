part of 'location_share_controller.dart';

class LocationShareController extends GetxController {
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  RxBool isDragging = false.obs;
  RxString currentAddress = ''.obs;
  String chatID;

  LocationShareController({required this.chatID});

  @override
  void onInit() {
    super.onInit();
    _handleRuntimeInit();
  }
}
