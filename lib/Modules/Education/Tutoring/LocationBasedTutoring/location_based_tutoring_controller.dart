import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class LocationBasedTutoringController extends GetxController {
  var isLoading = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLocationBasedTutoring();
  }

  Future<void> _batchFetchUsers(Set<String> userIds) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      for (var i = 0; i < toFetch.length; i += 30) {
        final batch = toFetch.skip(i).take(30).toList();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (var doc in snap.docs) {
          users[doc.id] = doc.data();
        }
      }
    } catch (e) {
      log("Error batch fetching users: $e");
    }
  }

  Future<void> fetchLocationBasedTutoring() async {
    isLoading.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
      String currentCity = await _getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('educators')
          .where('sehir', isEqualTo: currentCity)
          .limit(100)
          .get();
      List<TutoringModel> tempList = querySnapshot.docs
          .map(
            (doc) => TutoringModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // Batch fetch users instead of N+1
      final userIds = tempList.map((t) => t.userID).toSet();
      await _batchFetchUsers(userIds);

      // Mesafeye göre sırala (lat/long olan ilanlar önce, yakından uzağa)
      tempList.sort((a, b) {
        final aDist =
            _distanceKm(position.latitude, position.longitude, a.lat, a.long);
        final bDist =
            _distanceKm(position.latitude, position.longitude, b.lat, b.long);
        return aDist.compareTo(bDist);
      });

      tutoringList.value = tempList;
    } catch (e) {
      log("Error fetching location-based tutoring data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// İki nokta arasındaki mesafe (km). lat/long null ise sona at (çok büyük değer).
  double _distanceKm(double userLat, double userLon, double? lat, double? lon) {
    if (lat == null || lon == null) return 999999.0;
    return Geolocator.distanceBetween(userLat, userLon, lat, lon) / 1000.0;
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
