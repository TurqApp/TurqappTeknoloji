part of 'job_finder_controller.dart';

extension JobFinderControllerDataPart on JobFinderController {
  Future<void> _performPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) {
    final active = _startupPrepareFuture;
    if (active != null) {
      return active;
    }

    final future = _performRunPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
    );
    _startupPrepareFuture = future;
    future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
    return future;
  }

  Future<void> _performRunPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.jobFinder)) {
      return;
    }
    try {
      final allowRefresh = allowBackgroundRefresh ?? false;
      await _performHydrateJobFinderStartupShard();
      await _restoreListingSelection();
      unawaited(loadSehirler());
      await warmJobContentSavedIdsForCurrentUser();

      final currentUid = CurrentUserService.instance.effectiveUserId;
      _homeSnapshotSub ??= _jobHomeSnapshotRepository
          .openHome(
            userId: currentUid,
            limit: _jobFinderFullBootstrapLimit,
          )
          .listen(_applyHomeSnapshotResource);

      if (list.isEmpty) {
        await getStartData(
          silent: true,
          forceRefresh: false,
          limit: _jobFinderFullBootstrapLimit,
          deferLocationHydration: true,
        );
        return;
      }

      if (allowRefresh) {
        unawaited(
          getStartData(
            silent: true,
            forceRefresh: false,
            limit: _jobFinderFullBootstrapLimit,
            deferLocationHydration: true,
          ),
        );
      }
    } finally {
      unawaited(_persistJobFinderStartupShard());
      unawaited(_recordJobFinderStartupSurface());
    }
  }

  Future<void> _performHydrateJobFinderStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    _startupShardHydrated = false;
    _startupShardAgeMs = null;
    try {
      final shard = await ensureStartupSnapshotShardStore().load(
        surface: 'jobs',
        userId: userId,
        maxAge: StartupSnapshotShardStore.defaultFreshWindow,
      );
      if (shard == null) return;
      var didHydrate = false;
      final rawSelection = (shard.payload['listingSelection'] as num?)?.toInt();
      if (rawSelection != null) {
        listingSelection.value = rawSelection == 1 ? 1 : 0;
        listingSelectionReady.value = true;
        didHydrate = true;
      }
      final cityHint = (shard.payload['cityHint'] ?? '').toString().trim();
      if (cityHint.isNotEmpty) {
        sehir.value = cityHint;
        didHydrate = true;
      }
      final userCityHint =
          (shard.payload['userCityHint'] ?? '').toString().trim();
      if (userCityHint.isNotEmpty) {
        kullaniciSehiri.value = userCityHint;
        didHydrate = true;
      }
      final decoded = _decodeJobFinderStartupJobs(shard.payload['jobs']);
      if (decoded.isNotEmpty) {
        if (list.isEmpty) {
          list.assignAll(decoded);
          didHydrate = true;
        }
        if (allJobs.isEmpty) {
          allJobs.assignAll(decoded);
          didHydrate = true;
        }
      }
      if (!didHydrate) return;
      _startupShardHydrated = true;
      _startupShardAgeMs =
          DateTime.now().millisecondsSinceEpoch - shard.savedAtMs;
    } catch (_) {}
  }

  void _performHydrateJobFinderStartupSeedPoolSync() {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    try {
      final shard = ensureStartupSnapshotSeedPool().load(
        surface: 'jobs',
        userId: userId,
      );
      if (shard == null) return;
      final decoded = _decodeJobFinderStartupJobs(shard.payload['jobs']);
      if (decoded.isEmpty) return;
      final rawSelection = (shard.payload['listingSelection'] as num?)?.toInt();
      if (rawSelection != null) {
        listingSelection.value = rawSelection == 1 ? 1 : 0;
        listingSelectionReady.value = true;
      }
      if (list.isEmpty) {
        list.assignAll(decoded);
      }
      if (allJobs.isEmpty) {
        allJobs.assignAll(decoded);
      }
    } catch (_) {}
  }

  Future<void> _persistJobFinderStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final startupJobs = list
        .take(ReadBudgetRegistry.jobStartupShardLimit)
        .toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupJobs.isEmpty) {
      await store.clear(
        surface: 'jobs',
        userId: userId,
      );
      return;
    }
    await store.save(
      surface: 'jobs',
      userId: userId,
      itemCount: list.length,
      limit: ReadBudgetRegistry.jobStartupShardLimit,
      source: 'job_snapshot',
      payload: <String, dynamic>{
        'listingSelection': listingSelection.value == 1 ? 1 : 0,
        'cityHint': sehir.value.trim(),
        'userCityHint': kullaniciSehiri.value.trim(),
        'jobs': startupJobs
            .map(
              (job) => <String, dynamic>{
                'docID': job.docID,
                'data': job.toMap(),
              },
            )
            .toList(growable: false),
      },
    );
  }

  Future<void> _recordJobFinderStartupSurface() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final itemCount = list.length;
    final hasLocalSnapshot = itemCount > 0;
    try {
      await ensureStartupSnapshotManifestStore().recordSurfaceState(
        surface: 'jobs',
        userId: userId,
        itemCount: itemCount,
        hasLocalSnapshot: hasLocalSnapshot,
        source: hasLocalSnapshot ? 'job_snapshot' : 'none',
        startupShardHydrated: _startupShardHydrated,
        startupShardAgeMs: _startupShardAgeMs,
      );
    } catch (_) {}
  }

  List<JobModel> _decodeJobFinderStartupJobs(dynamic raw) {
    if (raw is! List) return const <JobModel>[];
    return raw
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
          final docId = (map['docID'] ?? '').toString().trim();
          final data = map['data'];
          if (docId.isEmpty || data is! Map) return null;
          try {
            return JobModel.fromMap(
              Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
              docId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<JobModel>()
        .toList(growable: false);
  }

  Future<void> searchFromTypesense(String query) async {
    final requestId = ++_searchRequestId;
    isLoading.value = true;
    try {
      final resource = await _jobHomeSnapshotRepository.search(
        query: query,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: ReadBudgetRegistry.jobSearchInitialLimit,
        forceSync: true,
      );
      if (requestId != _searchRequestId || search.text.trim() != query) return;

      final results = resource.data ?? const <JobModel>[];
      if (requestId != _searchRequestId || search.text.trim() != query) return;
      final nextResults = _applyDistanceToJobs(results);
      if (!_sameJobEntries(aramaSonucu, nextResults)) {
        aramaSonucu.assignAll(nextResults);
      }
    } catch (_) {
      if (requestId == _searchRequestId) {
        aramaSonucu.clear();
      }
    } finally {
      if (requestId == _searchRequestId) {
        isLoading.value = false;
      }
    }
  }

  Future<void> bootstrapStartData() async {
    final currentUid = CurrentUserService.instance.effectiveUserId;
    await warmJobContentSavedIdsForCurrentUser();
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _jobHomeSnapshotRepository
        .openHome(
          userId: currentUid,
          limit: _jobFinderFullBootstrapLimit,
        )
        .listen(_applyHomeSnapshotResource);
  }

  Future<void> getStartData({
    bool silent = false,
    bool forceRefresh = false,
    int limit = _jobFinderFullBootstrapLimit,
    bool deferLocationHydration = false,
  }) async {
    final shouldShowLoader = !silent && list.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final resource = await _jobHomeSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: limit,
        forceSync: forceRefresh,
      );
      final fetchedJobs = _applyCurrentSorting(
        resource.data ?? const <JobModel>[],
      );
      final shouldPreserveExistingJobs =
          fetchedJobs.isEmpty && (list.isNotEmpty || allJobs.isNotEmpty);
      final hydrationSourceJobs = shouldPreserveExistingJobs
          ? _applyCurrentSorting(List<JobModel>.from(
              allJobs.isNotEmpty ? allJobs : list,
            ))
          : fetchedJobs;
      if (!shouldPreserveExistingJobs && !_sameJobList(fetchedJobs)) {
        list.assignAll(fetchedJobs);
        allJobs.assignAll(fetchedJobs);
      }
      SilentRefreshGate.markRefreshed('jobs:home');
      if (shouldShowLoader) {
        isLoading.value = false;
      }

      if (deferLocationHydration) {
        _scheduleLocationHydration(hydrationSourceJobs);
      } else {
        unawaited(_hydrateLocationAndResort(
          hydrationSourceJobs,
          allowPermissionPrompt: false,
        ));
      }
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  void _scheduleLocationHydration(List<JobModel> sourceJobs) {
    _deferredLocationTimer?.cancel();
    _deferredLocationTimer = Timer(const Duration(milliseconds: 450), () {
      if (isClosed) return;
      unawaited(_hydrateLocationAndResort(
        sourceJobs,
        allowPermissionPrompt: false,
      ));
    });
  }

  Future<void> _hydrateLocationAndResort(
    List<JobModel> sourceJobs, {
    required bool allowPermissionPrompt,
  }) async {
    try {
      final position = await _resolveUserPosition(
        allowPermissionPrompt: allowPermissionPrompt,
      );
      if (position == null) {
        return;
      }
      final userLat = position.latitude;
      final userLong = position.longitude;
      _userLat = userLat;
      _userLong = userLong;

      final placemarks = await placemarkFromCoordinates(userLat, userLong);

      if (placemarks.isNotEmpty) {
        final cityName = placemarks.first.administrativeArea ?? '';
        sehir.value = cityName;
        kullaniciSehiri.value = cityName;
      }

      final updatedJobs = sourceJobs.map((job) {
        final distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLong,
          job.lat,
          job.long,
        );
        final distanceInKm = distanceInMeters / 1000;

        return job.copyWith(
          kacKm: double.parse(distanceInKm.toStringAsFixed(2)),
        );
      }).toList();

      final sortedJobs = _applyCurrentSorting(updatedJobs);
      if (_sameJobEntries(allJobs, sortedJobs) && _sameJobList(sortedJobs)) {
        return;
      }
      if (!_sameJobList(sortedJobs)) {
        list.assignAll(sortedJobs);
      }
      if (!_sameJobEntries(allJobs, sortedJobs)) {
        allJobs.assignAll(sortedJobs);
      }
    } catch (_) {}
  }

  Future<Position?> _resolveUserPosition({
    required bool allowPermissionPrompt,
  }) async {
    try {
      final lastResolved = _lastResolvedPosition;
      if (lastResolved != null) {
        return lastResolved;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!allowPermissionPrompt) {
          return await Geolocator.getLastKnownPosition();
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _lastResolvedPosition = lastKnown;
        return lastKnown;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _lastResolvedPosition = current;
      return current;
    } catch (_) {
      return null;
    }
  }

  JobModel _attachDistance(JobModel job) {
    final userLat = _userLat;
    final userLong = _userLong;
    if (userLat == null || userLong == null) return job;

    final distanceInKm = Geolocator.distanceBetween(
          userLat,
          userLong,
          job.lat,
          job.long,
        ) /
        1000;
    return job.copyWith(kacKm: double.parse(distanceInKm.toStringAsFixed(2)));
  }

  List<JobModel> _applyDistanceToJobs(List<JobModel> jobs) {
    return jobs.map(_attachDistance).toList(growable: false);
  }

  List<JobModel> _applyCurrentSorting(List<JobModel> jobs) {
    final sorted = List<JobModel>.from(jobs);
    applySorting(sorted);
    return sorted;
  }

  void _applyHomeSnapshotResource(CachedResource<List<JobModel>> resource) {
    final jobs = resource.data ?? const <JobModel>[];
    if (jobs.isNotEmpty) {
      final withDistance = _applyCurrentSorting(_applyDistanceToJobs(jobs));
      if (!_sameJobList(withDistance)) {
        list.assignAll(withDistance);
        allJobs.assignAll(withDistance);
      }
      _scheduleLocationHydration(withDistance);
    }

    if (!resource.isRefreshing || jobs.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (list.isEmpty) {
      isLoading.value = true;
    }
  }

  Future<void> loadSehirler() async {
    try {
      sehirlerVeIlcelerData.value =
          await _cityDirectoryService.getCitiesAndDistricts();
      sehirler.value = await _cityDirectoryService.getSortedCities(
        includeAllTurkey: true,
      );
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showIlSec() async {
    final sehirlerlist = List<String>.from(sehirler);
    sehirlerlist.remove(sehir.value);
    sehirlerlist.insert(0, sehir.value);
    if (sehir.value != kullaniciSehiri.value) {
      sehirlerlist.insert(1, kullaniciSehiri.value);
    }
    final uniqueCities = sehirlerlist.toSet().toList();
    final pinned = <String>[];
    for (final city in uniqueCities) {
      if (city == sehir.value || city == kullaniciSehiri.value) {
        pinned.add(city);
      }
    }
    final others = uniqueCities
        .where((city) => !pinned.contains(city) && !isAllTurkeySelection(city))
        .toList();
    sortTurkishStrings(others);
    final visibleCities = <String>[
      if (uniqueCities.any(isAllTurkeySelection)) _allTurkeyLabel,
      ...pinned
          .where((city) => city.isNotEmpty && !isAllTurkeySelection(city))
          .map((city) => city),
      ...others,
    ];
    Get.bottomSheet(
      SizedBox(
        height: Get.height / 2,
        child: ListBottomSheet(
          list: visibleCities,
          title: "pasaj.job_finder.select_city".tr,
          startSelection: sehir.value,
          onBackData: (v) {
            sehir.value = v;

            filtre.value = false;
            short.value = 0;

            if (isAllTurkeySelection(v)) {
              list.value = allJobs.where((job) => !job.ended).toList();
            } else {
              list.value =
                  allJobs.where((job) => job.city == v && !job.ended).toList();
            }
          },
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }
}
