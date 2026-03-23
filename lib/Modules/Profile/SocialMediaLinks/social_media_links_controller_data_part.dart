part of 'social_media_links_controller.dart';

extension SocialMediaControllerDataPart on SocialMediaController {
  void _bindFormListeners() {
    selected.listen((_) => updateEnableSave());
    textController.addListener(updateEnableSave);
    urlController.addListener(updateEnableSave);
  }

  Future<void> _bootstrapDataImpl() async {
    if (currentUid.isEmpty) {
      isLoading.value = false;
      list.value = <SocialMediaModel>[];
      return;
    }
    final cached = await _linksRepository.getLinks(
      currentUid,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.value = List<SocialMediaModel>.from(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'profile:social_media:$currentUid',
        minInterval: SocialMediaController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      list.value = <SocialMediaModel>[];
      isLoading.value = false;
      return;
    }
    if (!silent) {
      isLoading.value = true;
    }
    try {
      list.value = List<SocialMediaModel>.from(
        await _linksRepository.getLinks(
          uid,
          preferCache: !forceRefresh,
          forceRefresh: forceRefresh,
        ),
      );
      SilentRefreshGate.markRefreshed('profile:social_media:$uid');
    } finally {
      isLoading.value = false;
    }
  }
}
