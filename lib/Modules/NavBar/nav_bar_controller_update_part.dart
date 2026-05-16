part of 'nav_bar_controller.dart';

extension _NavBarControllerUpdatePart on NavBarController {
  Future<void> _launchStore() => _launchStoreImpl();

  int _asConfigInt(Object? value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  int _parseBuildNumberImpl(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  Future<void> _loadAppVersionConfigImpl({bool forceRefresh = false}) async {
    final repo = ensureConfigRepository();
    final doc = await repo.getAdminConfigDoc(
          _appVersionDocId,
          preferCache: !forceRefresh,
          forceRefresh: forceRefresh,
        ) ??
        await repo.getLegacyConfigDoc(
          collection: 'Yönetim',
          docId: 'Genel',
          preferCache: true,
        );

    if (doc == null) return;

    _appUpdateCheckEnabled = doc['updateCheckEnabled'] != false;
    _androidMinVersion = (doc['androidMinVersion'] ?? '').toString().trim();
    _iosMinVersion = (doc['iosMinVersion'] ?? '').toString().trim();
    _androidMinBuild = _asConfigInt(
      doc['androidMinBuild'] ??
          doc['androidMinBuildNumber'] ??
          doc['androidMinVersionCode'],
      0,
    );
    _iosMinBuild = _asConfigInt(
      doc['iosMinBuild'] ?? doc['iosMinBuildNumber'],
      0,
    );

    final updateTitle = (doc['updateTitle'] ?? '').toString().trim();
    final updateBody = (doc['updateBody'] ?? '').toString().trim();
    _updateTitle = updateTitle.isEmpty ? 'app_update.title'.tr : updateTitle;
    _updateBody = updateBody.isEmpty ? 'app_update.body'.tr : updateBody;

    final androidStoreUrl = (doc['androidStoreUrl'] ?? '').toString().trim();
    final iosStoreUrl = (doc['iosStoreUrl'] ?? '').toString().trim();
    _androidStoreUrlOverride = androidStoreUrl.isEmpty ? null : androidStoreUrl;
    _iosStoreUrlOverride = iosStoreUrl.isEmpty ? null : iosStoreUrl;

    _ratingPromptEnabled = doc['ratingPromptEnabled'] != false;
    final initialDays = _asConfigInt(doc['ratingPromptInitialDelayDays'], 7);
    final repeatDays = _asConfigInt(doc['ratingPromptRepeatDays'], 7);
    final cooldownDays = _asConfigInt(
      doc['ratingPromptStoreCooldownDays'],
      90,
    );
    _ratingPromptEnabledAfter =
        Duration(days: initialDays < 1 ? 7 : initialDays);
    _ratingPromptRepeatAfter = Duration(days: repeatDays < 1 ? 7 : repeatDays);
    _ratingPromptStoreCooldown =
        Duration(days: cooldownDays < 1 ? 90 : cooldownDays);
  }

  Future<void> _checkAppVersionImpl({bool forceRefresh = true}) async {
    try {
      if (kDebugMode) {
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = _parseBuildNumberImpl(packageInfo.buildNumber);
      await _loadAppVersionConfigImpl(forceRefresh: forceRefresh);
      if (!_appUpdateCheckEnabled) return;

      var requiredVersion = '';
      var requiredBuild = 0;
      if (Platform.isAndroid) {
        requiredVersion = _androidMinVersion;
        requiredBuild = _androidMinBuild;
      } else if (Platform.isIOS) {
        requiredVersion = _iosMinVersion;
        requiredBuild = _iosMinBuild;
      }

      final versionTooLow = requiredVersion.isNotEmpty &&
          _isVersionLowerImpl(currentVersion, requiredVersion);
      final buildTooLow =
          requiredBuild > 0 && currentBuild > 0 && currentBuild < requiredBuild;

      debugPrint(
        '[AppUpdateCheck] platform=${Platform.isAndroid ? 'android' : 'ios'} '
        'current=$currentVersion+$currentBuild '
        'required=$requiredVersion+$requiredBuild '
        'versionTooLow=$versionTooLow buildTooLow=$buildTooLow',
      );

      if (versionTooLow || buildTooLow) {
        _showUpdateDialogImpl(
          requiredVersion: requiredVersion,
          requiredBuild: requiredBuild,
        );
      }
    } catch (_) {}
  }

  Future<void> _checkAppVersionDailyImpl() async {
    if (kDebugMode) return;
    try {
      final preferences = ensureLocalPreferenceRepository();
      final now = DateTime.now();
      final lastCheckedMs =
          await preferences.getInt(_appVersionLastCheckedAtKey) ?? 0;
      if (lastCheckedMs > 0) {
        final lastChecked = DateTime.fromMillisecondsSinceEpoch(lastCheckedMs);
        final alreadyCheckedToday = lastChecked.year == now.year &&
            lastChecked.month == now.month &&
            lastChecked.day == now.day;
        if (alreadyCheckedToday) {
          debugPrint('[AppUpdateCheck] source=cache reason=daily_gate');
          await _checkAppVersionImpl(forceRefresh: false);
          return;
        }
      }

      await _checkAppVersionImpl(forceRefresh: true);
      await preferences.setInt(
        _appVersionLastCheckedAtKey,
        now.millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  bool _isVersionLowerImpl(String currentVersion, String requiredVersion) {
    final current = currentVersion
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final required = requiredVersion
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    for (var i = 0; i < 3; i++) {
      final currentPart = i < current.length ? current[i] : 0;
      final requiredPart = i < required.length ? required[i] : 0;

      if (currentPart < requiredPart) return true;
      if (currentPart > requiredPart) return false;
    }

    return false;
  }

  String _appUpdatePromptCountKeyImpl({
    required String requiredVersion,
    required int requiredBuild,
  }) {
    final platform = Platform.isIOS ? 'ios' : 'android';
    return '$_appVersionPromptCountKeyPrefix:$platform:'
        '${requiredVersion.isEmpty ? 'any' : requiredVersion}:$requiredBuild';
  }

  void _showUpdateDialogImpl({
    required String requiredVersion,
    required int requiredBuild,
  }) {
    if (_isForceUpdateVisible) return;
    _isForceUpdateVisible = true;
    unawaited(() async {
      final preferences = ensureLocalPreferenceRepository();
      final countKey = _appUpdatePromptCountKeyImpl(
        requiredVersion: requiredVersion,
        requiredBuild: requiredBuild,
      );
      final showCount = (await preferences.getInt(countKey) ?? 0) + 1;
      await preferences.setInt(countKey, showCount);
      final forceUpdate = showCount >= 5;
      debugPrint(
        '[AppUpdateCheck] action=show_update_sheet count=$showCount '
        'force=$forceUpdate key=$countKey',
      );
      await Get.bottomSheet<void>(
        isDismissible: !forceUpdate,
        enableDrag: !forceUpdate,
        barrierColor: Colors.black54,
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _updateTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "MontserratBold",
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _updateBody,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: "MontserratMedium",
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                30.ph,
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'app_update.cta'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!forceUpdate) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: Get.back<void>,
                    child: const Text(
                      'Sonra',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
      _isForceUpdateVisible = false;
    }());
  }

  void _scheduleRatingPromptImpl(Duration delay) {
    _ratingPromptTimer?.cancel();
    _ratingPromptTimer = Timer(delay, () {
      if (_isDisposed) return;
      unawaited(_maybeShowRatingPromptImpl());
    });
  }

  Future<void> _maybeShowRatingPromptImpl() async {
    if (_isDisposed ||
        _isForceUpdateVisible ||
        _ratingSheetShownThisSession ||
        selectedIndex.value != 0) {
      return;
    }
    await _loadAppVersionConfigImpl(forceRefresh: false);
    if (!_ratingPromptEnabled) {
      return;
    }
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
      _scheduleRatingPromptImpl(const Duration(seconds: 45));
      return;
    }

    final preferences = ensureLocalPreferenceRepository();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final firstSeenMs = await preferences.getInt(_ratingFirstSeenAtKey) ?? 0;
    final lastShownMs = await preferences.getInt(_ratingLastShownAtKey) ?? 0;
    final lastStoreTapMs =
        await preferences.getInt(_ratingLastStoreTapAtKey) ?? 0;

    if (firstSeenMs <= 0) {
      await preferences.setInt(_ratingFirstSeenAtKey, nowMs);
      return;
    }

    final firstSeenAt = DateTime.fromMillisecondsSinceEpoch(firstSeenMs);
    if (DateTime.now().difference(firstSeenAt) < _ratingPromptEnabledAfter) {
      return;
    }

    if (lastShownMs > 0) {
      final lastShownAt = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
      if (DateTime.now().difference(lastShownAt) < _ratingPromptRepeatAfter) {
        return;
      }
    }

    if (lastStoreTapMs > 0) {
      final lastStoreTapAt =
          DateTime.fromMillisecondsSinceEpoch(lastStoreTapMs);
      if (DateTime.now().difference(lastStoreTapAt) <
          _ratingPromptStoreCooldown) {
        return;
      }
    }

    _ratingSheetShownThisSession = true;
    await preferences.setInt(_ratingLastShownAtKey, nowMs);

    await Get.bottomSheet(
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black38,
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1EA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.black,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'nav.rating_prompt_title'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontFamily: 'MontserratBold',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'nav.rating_prompt_body'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontFamily: 'MontserratMedium',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await preferences.setInt(
                      _ratingLastStoreTapAtKey,
                      nowMs,
                    );
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                    await _launchStoreImpl();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'nav.rating_prompt_cta'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'nav.rating_prompt_later'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchStoreImpl() async {
    var storeUrl = "";

    if (Platform.isAndroid) {
      storeUrl = _androidStoreUrlOverride ??
          "https://play.google.com/store/apps/details?id=com.turqapp.app";
    } else if (Platform.isIOS) {
      storeUrl = _iosStoreUrlOverride ??
          "https://apps.apple.com/tr/app/turqapp/id6740809479?l=tr";
    }

    if (storeUrl.isNotEmpty) {
      final url = Uri.parse(storeUrl);
      try {
        await confirmAndLaunchExternalUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        AppSnackbar(
          'common.error'.tr,
          'nav.store_open_failed'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
      }
    }
  }
}
