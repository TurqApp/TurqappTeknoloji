import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    currentPosition.value = LatLng(pos.latitude, pos.longitude);
    _getAddressFromLatLng(pos.latitude, pos.longitude);
    mapController.value
        ?.animateCamera(CameraUpdate.newLatLng(currentPosition.value!));
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
  }

  void onCameraMove(CameraPosition position) {
    isDragging.value = true;
  }

  void onCameraIdle() async {
    isDragging.value = false;
    final center = await mapController.value!.getLatLng(
      ScreenCoordinate(x: 180, y: 350),
    );

    currentPosition.value = center;
    _getAddressFromLatLng(center.latitude, center.longitude);
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        currentAddress.value =
            "${place.street}, ${place.locality}, ${place.administrativeArea}";
        print("Adres: ${currentAddress.value}");
      }
    } catch (e) {
      print("Adres alınamadı: $e");
    }
  }

  void moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final pos = LatLng(position.latitude, position.longitude);
      currentPosition.value = pos;
      _getAddressFromLatLng(pos.latitude, pos.longitude);

      final controller = mapController.value;
      if (controller != null) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: pos,
              zoom: 16.5,
              tilt: 0,
              bearing: 0,
            ),
          ),
        );
      }
    } catch (e) {
      print("Konuma gidilemedi: $e");
    }
  }

  @override
  void onClose() {
    mapController.value?.dispose();
    mapController.value = null;
    super.onClose();
  }
}
