part of 'profile_controller.dart';

extension ProfileControllerHeaderPart on ProfileController {
  String _preserveNonEmpty(
    RxString target,
    dynamic raw,
  ) {
    final next = (raw ?? '').toString().trim();
    if (next.isNotEmpty) return next;
    return target.value.trim();
  }

  Future<void> _performBootstrapProfileData() async {
    await _performRestoreCachedListsForActiveUser();
    await _performBootstrapHeaderFromTypesense();
    getCounters();
    _listenToCounterChanges();
    _bindResharesRealtime();
    unawaited(_loadInitialPrimaryBuckets());
    getReshares();
  }

  Future<void> _performBootstrapHeaderFromTypesense() async {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    try {
      final summary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
        cacheOnly: false,
      );
      final cachedRaw = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final bootstrapData = cachedRaw ??
          (summary != null ? summary.toMap() : const <String, dynamic>{});
      if (bootstrapData.isEmpty) return;
      _performApplyHeaderCard(bootstrapData);
      if (_performNeedsHeaderSupplementalData(bootstrapData)) {
        final raw = await _userRepository.getUserRaw(
          uid,
          preferCache: false,
          forceServer: true,
        );
        if (raw != null && raw.isNotEmpty) {
          await _userRepository.putUserRaw(uid, raw);
          _performApplyHeaderCard(raw);
        }
      }
    } catch (e) {
      print('_bootstrapHeaderFromTypesense error: $e');
    }
  }

  bool _performNeedsHeaderSupplementalData(Map<String, dynamic> data) {
    final bioText = (data['bio'] ?? '').toString().trim();
    final addressText = (data['adres'] ?? '').toString().trim();
    final meslekText = (data['meslekKategori'] ?? '').toString().trim();
    return bioText.isEmpty || addressText.isEmpty || meslekText.isEmpty;
  }

  void _performApplyHeaderCard(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    headerNickname.value =
        (data['nickname'] ?? data['username'] ?? '').toString().trim();
    headerRozet.value =
        (data['rozet'] ?? data['badge'] ?? '').toString().trim();
    headerDisplayName.value = (data['displayName'] ?? '').toString().trim();
    headerAvatarUrl.value = resolveAvatarUrl(data, profile: profile);

    final display = headerDisplayName.value.trim();
    if (display.isNotEmpty) {
      headerFirstName.value = display;
      headerLastName.value = '';
    } else {
      headerFirstName.value =
          _preserveNonEmpty(headerFirstName, data['firstName']);
      headerLastName.value =
          _preserveNonEmpty(headerLastName, data['lastName']);
    }
    headerMeslek.value =
        _preserveNonEmpty(headerMeslek, data['meslekKategori']);
    headerBio.value = _preserveNonEmpty(headerBio, data['bio']);
    headerAdres.value = _preserveNonEmpty(headerAdres, data['adres']);
  }

  Future<void> _performShowSocialMediaLinkDelete(String docID) async {
    await noYesAlert(
      title: "profile.link_remove_title".tr,
      message: "profile.link_remove_body".tr,
      cancelText: "common.cancel".tr,
      yesText: "common.remove".tr,
      onYesPressed: () async {
        final uid = _resolvedActiveUid;
        if (uid == null || uid.isEmpty) return;
        await _socialLinksRepository.deleteLink(uid, docID);
        unawaited(
          SocialMediaController.maybeFind()?.getData(
                silent: true,
                forceRefresh: true,
              ) ??
              Future.value(),
        );
      },
    );
  }
}
