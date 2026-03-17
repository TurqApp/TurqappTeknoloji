import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class LocationBasedTutoringController extends GetxController {
  static const String _cacheKey = 'location_tutoring_cache_v1';
  final UserRepository _userRepository = UserRepository.ensure();
  var isLoading = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cached = await _readCache();
    if (cached.isNotEmpty) {
      tutoringList.assignAll(cached);
      await _batchFetchUsers(
        cached.map((t) => t.userID).where((id) => id.isNotEmpty).toSet(),
        cacheOnly: true,
      );
      isLoading.value = false;
      await fetchLocationBasedTutoring(silent: true);
      return;
    }
    await fetchLocationBasedTutoring();
  }

  Future<void> _batchFetchUsers(
    Set<String> userIds, {
    bool cacheOnly = false,
  }) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      final fetched = await _userRepository.getUsersRaw(
        toFetch,
        cacheOnly: cacheOnly,
      );
      users.addAll(fetched);
    } catch (_) {
    }
  }

  Future<void> fetchLocationBasedTutoring({
    bool silent = false,
  }) async {
    if (!silent || tutoringList.isEmpty) {
      isLoading.value = true;
    }
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

      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.tutoring,
        query: '*',
        limit: 250,
        page: 1,
      );
      final tempList = result.hits
          .map(TutoringModel.fromTypesenseHit)
          .where((item) => item.docID.isNotEmpty)
          .where((item) =>
              item.sehir.trim().toLowerCase() == currentCity.trim().toLowerCase())
          .toList(growable: true);

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
      await _writeCache(tempList);
    } catch (_) {
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
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _writeCache(List<TutoringModel> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(
          items
              .map((item) => <String, dynamic>{
                    'docID': item.docID,
                    'data': item.toJson(),
                  })
              .toList(growable: false),
        ),
      );
    } catch (_) {}
  }

  Future<List<TutoringModel>> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return const <TutoringModel>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <TutoringModel>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(
            (item) => TutoringModel.fromJson(
              Map<String, dynamic>.from(item['data'] as Map? ?? const {}),
              (item['docID'] ?? '').toString(),
            ),
          )
          .where((item) => item.docID.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <TutoringModel>[];
    }
  }
}
