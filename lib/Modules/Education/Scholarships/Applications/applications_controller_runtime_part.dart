part of 'applications_controller.dart';

extension ApplicationsControllerRuntimeX on ApplicationsController {
  Future<void> _handleOnInit() async {
    final userID = CurrentUserService.instance.effectiveUserId;
    if (userID.isEmpty) {
      isLoading.value = false;
      return;
    }
    final cached = await _loadApplications(cacheOnly: true);
    if (cached.isNotEmpty) {
      applications.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'scholarships:applications:$userID',
        minInterval: _applicationsSilentRefreshInterval,
      )) {
        unawaited(fetchApplications(silent: true, forceRefresh: true));
      }
      return;
    }
    await fetchApplications();
  }

  Future<void> fetchApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    try {
      if (!silent || applications.isEmpty) {
        isLoading.value = true;
      }
      final applicationList = await _loadApplications(
        cacheOnly: false,
        forceRefresh: forceRefresh,
      );
      applications.assignAll(applicationList);
      final userID = CurrentUserService.instance.effectiveUserId;
      if (userID.isNotEmpty) {
        SilentRefreshGate.markRefreshed('scholarships:applications:$userID');
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'scholarship.applications_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadApplications({
    bool cacheOnly = false,
    bool forceRefresh = false,
  }) async {
    final userID = CurrentUserService.instance.effectiveUserId;
    if (userID.isEmpty) {
      throw StateError('Kullanıcı oturumu açık değil.');
    }

    final bursList = await _scholarshipRepository.fetchAppliedByUserRaw(
      userID,
      limit: 50,
      preferCache: !forceRefresh,
      forceRefresh: forceRefresh,
      cacheOnly: cacheOnly,
    );

    final ownerIds = bursList
        .map((d) => d['userID'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final userDocsById = ownerIds.isEmpty
        ? <String, UserSummary>{}
        : await _userSummaryResolver.resolveMany(
            ownerIds,
            cacheOnly: cacheOnly,
          );

    final applicationList = <Map<String, dynamic>>[];

    for (final data in bursList) {
      final bursOwnerID = data['userID'] as String? ?? '';
      final ownerData = userDocsById[bursOwnerID];
      final nickname = ownerData?.preferredName ?? 'common.unknown_user'.tr;
      final avatarUrl = ownerData?.avatarUrl ?? '';

      applicationList.add({
        'bursID': (data['docId'] ?? '').toString(),
        'title': data['baslik'] as String? ?? 'scholarship.title_label'.tr,
        'img': data['img'] as String? ?? '',
        'desc': data['aciklama'] as String? ?? 'scholarship.no_description'.tr,
        'basvuruKosullari':
            data['basvuruKosullari'] as String? ?? 'common.unspecified'.tr,
        'belgeler': data['belgeler'] as List<dynamic>? ?? [],
        'aylar': data['aylar'] as List<dynamic>? ?? [],
        'baslangicTarihi': data['baslangicTarihi'] as String? ?? '',
        'bitisTarihi': data['bitisTarihi'] as String? ?? '',
        'egitimKitlesi': data['egitimKitlesi'] as String? ?? '',
        'altEgitimKitlesi': data['altEgitimKitlesi'] as List<dynamic>? ?? [],
        'universiteler': data['universiteler'] as List<dynamic>? ?? [],
        'mukerrerDurumu': data['mukerrerDurumu'] as String? ?? '',
        'geriOdemeli': data['geriOdemeli'] as String? ?? '',
        'basvuruURL': data['basvuruURL'] as String? ?? '',
        'basvuruYapilacakYer': data['basvuruYapilacakYer'] as String? ?? '',
        'timeStamp': data['timeStamp'] as num? ?? 0,
        'tutar': data['tutar'] as String? ?? '',
        'ogrenciSayisi': data['ogrenciSayisi'] as String? ?? '',
        'sehirler': data['sehirler'] as List<dynamic>? ?? [],
        'hedefKitle': data['hedefKitle'] as String? ?? '',
        'nickname': nickname,
        'userID': bursOwnerID,
        'avatarUrl': avatarUrl,
      });
    }

    return applicationList;
  }

  Future<void> withdrawApplication(String bursID) async {
    try {
      final userID = CurrentUserService.instance.effectiveUserId;
      if (userID.isEmpty) {
        AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final docRef = ScholarshipFirestorePath.doc(bursID);
      batch.update(docRef, {
        'basvurular': FieldValue.arrayRemove([userID]),
      });
      batch.delete(docRef.collection('Basvurular').doc(userID));
      await batch.commit();

      applications.removeWhere((app) => app['bursID'] == bursID);
      Get.back();

      AppSnackbar(
        'common.success'.tr,
        'scholarship.withdraw_success'.tr,
      );
    } catch (e) {
      AppSnackbar('common.error'.tr, 'scholarship.withdraw_failed'.tr);
    }
  }
}
