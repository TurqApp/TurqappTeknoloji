part of 'personalized_controller.dart';

extension PersonalizedControllerDataPart on PersonalizedController {
  List<Map<String, dynamic>> _scholarshipDocsFromSnapshot(
    List<Map<String, dynamic>> items,
  ) {
    return items.map((item) {
      final model = item['model'] as IndividualScholarshipsModel?;
      final docId = (item['docId'] ?? '').toString().trim();
      return <String, dynamic>{
        ...(model?.toJson() ?? const <String, dynamic>{}),
        if (docId.isNotEmpty) 'docId': docId,
      };
    }).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadLatestScholarshipDocs({
    required int limit,
    bool forceSync = false,
  }) async {
    final result = await _scholarshipSnapshotRepository.loadHome(
      userId: CurrentUserService.instance.effectiveUserId,
      limit: limit,
      forceSync: forceSync,
    );
    return _scholarshipDocsFromSnapshot(
      result.data?.items ?? const <Map<String, dynamic>>[],
    );
  }

  Future<void> _initializeData() async {
    try {
      await _loadCachedList();
      await _loadUserData();

      if (!hasSchoolInfo.value) {
        await getUserLocation();
      }

      _loadVitrinData();
      await _loadScholarshipsData();
    } catch (_) {
    } finally {
      isInitialLoading.value = false;
    }
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isLoading.value) {
        _loadMoreData();
      }
    });
  }

  void _loadMoreData() {
    if (!isLoading.value && isUserDataLoaded.value) {
      isLoading.value = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        isLoading.value = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;

      final data = await _userRepository.getUserRaw(uid);
      if (data != null) {
        _updateUserData(data);
        isUserDataLoaded.value = true;
      }
    } catch (_) {}
  }

  void _updateUserData(Map<String, dynamic> data) {
    final educationLevel =
        userString(data, key: 'educationLevel', scope: 'education');
    final uni = userString(data, key: 'universite', scope: 'education');
    final hs = userString(data, key: 'lise', scope: 'education');
    final ms = userString(data, key: 'ortaOkul', scope: 'education');
    final il = (data['il'] ?? '').toString();

    hasSchoolInfo.value = educationLevel.isNotEmpty ||
        uni.isNotEmpty ||
        hs.isNotEmpty ||
        ms.isNotEmpty;
    schoolCity.value = hasSchoolInfo.value ? il : '';
    this.educationLevel.value = educationLevel;

    ikametSehir.value = data['ikametSehir'] ?? '';
    ikametIlce.value = data['ikametIlce'] ?? '';
    nufusSehir.value = data['nufusSehir'] ?? '';
    nufusIlce.value = data['nufusIlce'] ?? '';
    universite.value = uni;
    ortaokul.value = ms;
    lise.value = hs;
    cinsiyet.value = data['cinsiyet'] ?? '';
    locationSehir.value = data['locationSehir'] ?? '';
  }

  void _loadVitrinData() {
    _loadLatestScholarshipDocs(
      limit: ReadBudgetRegistry.scholarshipPersonalizedShowcaseLimit,
    ).then((items) {
      if (items.isNotEmpty) {
        final tempList = items
            .map((item) => IndividualScholarshipsModel.fromJson(item))
            .toList(growable: false);
        vitrin.value = tempList;
      }
    }).catchError((_) {});
  }

  Future<void> _loadScholarshipsData() async {
    if (!isUserDataLoaded.value) return;

    try {
      final items = await _loadLatestScholarshipDocs(
        limit: ReadBudgetRegistry.scholarshipPersonalizedInitialLimit,
      );
      _processScholarshipsData(items);
    } catch (_) {
      isLoading.value = false;
    }
  }

  Future<void> getUserLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        await _updateLocationData(place);
      }
    } catch (_) {}
  }

  Future<void> _updateLocationData(Placemark place) async {
    final newLocationSehir = place.administrativeArea ?? '';
    final newIkametSehir = place.administrativeArea ?? '';
    final newIkametIlce = place.subAdministrativeArea ?? '';

    ikametSehir.value = newIkametSehir;
    ikametIlce.value = newIkametIlce;
    nufusSehir.value = newIkametSehir;
    nufusIlce.value = newIkametIlce;
    locationSehir.value = newLocationSehir;

    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isNotEmpty) {
        await _userRepository.updateUserFields(uid, {
          ...scopedUserUpdate(
            scope: 'profile',
            values: {
              "locationSehir": newLocationSehir,
              "ikametSehir": newIkametSehir,
              "ikametIlce": newIkametIlce,
              "nufusSehir": newIkametSehir,
              "nufusIlce": newIkametIlce,
            },
          ),
        });
      }
    } catch (_) {}
  }

  Future<void> refreshList() async {
    list.clear();
    vitrin.clear();
    isInitialLoading.value = true;

    await _initializeData();
  }

  Future<void> _loadCachedList() async {
    try {
      final preferences = ensureLocalPreferenceRepository();
      final raw = await preferences.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map>()
          .map((e) => IndividualScholarshipsModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
      if (items.isNotEmpty) {
        list.value = items;
        count.value = items.length;
      }
    } catch (_) {}
  }

  Future<void> _saveCachedList(
      List<IndividualScholarshipsModel> allItems) async {
    try {
      if (allItems.isEmpty) return;
      final sorted = List<IndividualScholarshipsModel>.from(allItems)
        ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      final top =
          sorted.take(_personalizedCacheLimit).map((e) => e.toJson()).toList();
      final preferences = ensureLocalPreferenceRepository();
      await preferences.setString(_cacheKey, json.encode(top));
    } catch (_) {}
  }
}
