part of 'location_based_tutoring_controller.dart';

extension _LocationBasedTutoringControllerRuntimeX
    on LocationBasedTutoringController {
  Future<void> bootstrapData() async {
    final cached = await readCache();
    if (cached.isNotEmpty) {
      if (!_sameTutoringEntries(tutoringList, cached)) {
        tutoringList.assignAll(cached);
      }
      isLoading.value = false;
      await fetchLocationBasedTutoring(silent: true);
      return;
    }
    await fetchLocationBasedTutoring();
  }

  Future<void> fetchLocationBasedTutoring({
    bool silent = false,
  }) async {
    if (!silent || tutoringList.isEmpty) {
      isLoading.value = true;
    }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final currentCity = await getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final result = await _tutoringSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 250,
        forceSync: !silent,
      );
      final tempList = (result.data ?? const <TutoringModel>[])
          .where((item) => item.docID.isNotEmpty)
          .where((item) =>
              normalizeLocationText(item.sehir) ==
              normalizeLocationText(currentCity))
          .toList(growable: true);

      tempList.sort((a, b) {
        final aDist =
            distanceKm(position.latitude, position.longitude, a.lat, a.long);
        final bDist =
            distanceKm(position.latitude, position.longitude, b.lat, b.long);
        return aDist.compareTo(bDist);
      });

      if (!_sameTutoringEntries(tutoringList, tempList)) {
        tutoringList.value = tempList;
      }
      await writeCache(tempList);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  double distanceKm(double userLat, double userLon, double? lat, double? lon) {
    if (lat == null || lon == null) return 999999.0;
    return Geolocator.distanceBetween(userLat, userLon, lat, lon) / 1000.0;
  }

  Future<String> getCityFromCoordinates(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks.first.administrativeArea ??
            'settings.diagnostics.unknown'.tr;
      }
      return 'settings.diagnostics.unknown'.tr;
    } catch (_) {
      return 'settings.diagnostics.unknown'.tr;
    }
  }

  Future<void> writeCache(List<TutoringModel> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LocationBasedTutoringController._cacheKey,
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

  Future<List<TutoringModel>> readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(LocationBasedTutoringController._cacheKey);
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
