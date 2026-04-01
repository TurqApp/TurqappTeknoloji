part of 'scholarship_providers_controller.dart';

ScholarshipProvidersController ensureScholarshipProvidersController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindScholarshipProvidersController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ScholarshipProvidersController(),
    tag: tag,
    permanent: permanent,
  );
}

ScholarshipProvidersController? maybeFindScholarshipProvidersController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<ScholarshipProvidersController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ScholarshipProvidersController>(tag: tag);
}

extension ScholarshipProvidersControllerRuntimePart
    on ScholarshipProvidersController {
  Future<List<Map<String, dynamic>>> _loadProviderSeedItems({
    required bool cacheOnly,
    required bool forceRefresh,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    final resource = cacheOnly
        ? await _scholarshipSnapshotRepository.loadCachedHome(
            userId: userId,
            limit: ReadBudgetRegistry.scholarshipProviderSeedLimit,
          )
        : await _scholarshipSnapshotRepository.loadHome(
            userId: userId,
            limit: ReadBudgetRegistry.scholarshipProviderSeedLimit,
            forceSync: forceRefresh,
          );
    return resource.data?.items ?? const <Map<String, dynamic>>[];
  }

  void _handleInit() {
    unawaited(_bootstrapProviders());
  }

  Future<void> _bootstrapProviders() async {
    final cached = await _loadProviders(cacheOnly: true);
    if (cached.isNotEmpty) {
      providers.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'scholarships:providers',
        minInterval: _scholarshipProvidersSilentRefreshInterval,
      )) {
        unawaited(_fetchProvidersImpl(silent: true, forceRefresh: true));
      }
      return;
    }
    await _fetchProvidersImpl();
  }

  Future<void> _fetchProvidersImpl({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    try {
      if (!silent || providers.isEmpty) {
        isLoading.value = true;
      }
      final providerList = await _loadProviders(
        cacheOnly: false,
        forceRefresh: forceRefresh,
      );
      providers.assignAll(providerList);
      SilentRefreshGate.markRefreshed('scholarships:providers');
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.providers_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadProviders({
    bool cacheOnly = false,
    bool forceRefresh = false,
  }) async {
    final scholarships = await _loadProviderSeedItems(
      cacheOnly: cacheOnly,
      forceRefresh: forceRefresh,
    );

    final seenUserIDs = <String>{};
    for (final bursDoc in scholarships) {
      final userID = ((bursDoc['userData'] as Map?)?['userID'] ??
              bursDoc['userID'] ??
              (bursDoc['model'] as IndividualScholarshipsModel?)?.userID)
          ?.toString();
      if (userID != null && userID.isNotEmpty) {
        seenUserIDs.add(userID);
      }
    }

    if (seenUserIDs.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final providerList = <Map<String, dynamic>>[];
    final userIdsList = seenUserIDs.toList();
    for (var i = 0; i < userIdsList.length; i += 30) {
      final end = (i + 30) > userIdsList.length ? userIdsList.length : (i + 30);
      final batchIds = userIdsList.sublist(i, end);
      final users = await _userRepository.getUsers(
        batchIds,
        cacheOnly: cacheOnly,
      );
      for (final entry in users.entries) {
        final userDocId = entry.key;
        final user = entry.value.toMap();
        final profileImage = (user['avatarUrl'] ?? '').toString();
        final profileName = (user['displayName'] ??
                user['username'] ??
                user['nickname'] ??
                'common.unknown_user'.tr)
            .toString();
        providerList.add({
          'userID': userDocId,
          'avatarUrl': profileImage,
          'nickname': profileName,
          'displayName': profileName,
          'rozet': user['rozet'] as String? ?? '',
        });
      }
    }
    return providerList;
  }
}

extension ScholarshipProvidersControllerFacadePart
    on ScholarshipProvidersController {
  Future<void> fetchProviders({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _fetchProvidersImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
