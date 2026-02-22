import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/TutoringModel.dart';

class LocationBasedTutoringController extends GetxController {
  var isLoading = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLocationBasedTutoring();
  }

  Future<void> fetchLocationBasedTutoring() async {
    isLoading.value = true;
    try {
      // Cihazın konumunu al
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      String currentCity = await _getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('OzelDersVerenler')
              .where('sehir', isEqualTo: currentCity)
              .get();
      List<TutoringModel> tempList =
          querySnapshot.docs
              .map(
                (doc) => TutoringModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      for (var tutoring in tempList) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(tutoring.userID)
                .get();
        if (userDoc.exists) {
          users[tutoring.userID] = userDoc.data() as Map<String, dynamic>;
        }
      }

      tutoringList.value = tempList;
    } catch (e) {
      log("Error fetching location-based tutoring data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _getCityFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks.first.administrativeArea ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      log("Error getting city from coordinates: $e");
      return 'Unknown';
    }
  }
}
