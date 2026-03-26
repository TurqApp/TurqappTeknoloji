part of 'location_share_controller.dart';

extension LocationShareControllerRuntimePart on LocationShareController {
  void _handleRuntimeInit() {
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    currentPosition.value = LatLng(position.latitude, position.longitude);
    await _getAddressFromLatLng(position.latitude, position.longitude);
    mapController.value
        ?.animateCamera(CameraUpdate.newLatLng(currentPosition.value!));
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
  }

  void onCameraMove(CameraPosition position) {
    isDragging.value = true;
  }

  Future<void> onCameraIdle() async {
    isDragging.value = false;
    final center = await mapController.value!.getLatLng(
      const ScreenCoordinate(x: 180, y: 350),
    );
    currentPosition.value = center;
    await _getAddressFromLatLng(center.latitude, center.longitude);
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;
      final place = placemarks.first;
      currentAddress.value =
          "${place.street}, ${place.locality}, ${place.administrativeArea}";
      print("Adres: ${currentAddress.value}");
    } catch (e) {
      print("Adres alınamadı: $e");
    }
  }

  void shareLocation() {
    final pos = currentPosition.value;
    if (pos == null) return;

    print("Konum paylaşıldı: ${pos.latitude}, ${pos.longitude}");
    print("Adres: ${currentAddress.value}");

    final controller = maybeFindChatController(tag: chatID);
    if (controller == null) return;
    controller.textEditingController.text = currentAddress.value;
    controller.sendMessage(
        latLng: latlong2.LatLng(pos.latitude, pos.longitude));
    Get.back();
  }

  Future<void> moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final pos = LatLng(position.latitude, position.longitude);
      currentPosition.value = pos;
      await _getAddressFromLatLng(pos.latitude, pos.longitude);

      final controller = mapController.value;
      if (controller == null) return;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pos,
            zoom: 16.5,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    } catch (e) {
      print("Konuma gidilemedi: $e");
    }
  }
}
