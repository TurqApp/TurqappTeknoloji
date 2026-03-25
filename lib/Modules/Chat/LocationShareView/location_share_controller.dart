import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:latlong2/latlong.dart' as latlong2;

part 'location_share_controller_runtime_part.dart';

class LocationShareController extends GetxController {
  static LocationShareController ensure({
    required String chatID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      LocationShareController(chatID: chatID),
      tag: tag,
      permanent: permanent,
    );
  }

  static LocationShareController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<LocationShareController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<LocationShareController>(tag: tag);
  }

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
