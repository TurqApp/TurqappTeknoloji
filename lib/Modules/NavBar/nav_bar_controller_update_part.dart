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
    _updateTitle = updateTitle.isEmpty ? 'app_update.title'.tr : updateTitle;
    _updateBody =
        'Daha iyi performans ve yeni özellikler için lütfen uygulamanızı güncelleyiniz.';

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
        _handleRequiredAppUpdateImpl(
          requiredVersion: requiredVersion,
          requiredBuild: requiredBuild,
        );
      }
    } catch (_) {}
  }

  bool _isAppVersionCheckWeekdayImpl(DateTime time) =>
      _appVersionCheckWeekdays.contains(time.weekday);

  DateTime _nextAppUpdatePromptWindowStartImpl(
    DateTime from, {
    Duration reserveBeforeEnd = Duration.zero,
  }) {
    for (var dayOffset = 0; dayOffset < 14; dayOffset++) {
      final day = DateTime(from.year, from.month, from.day + dayOffset);
      if (!_isAppVersionCheckWeekdayImpl(day)) continue;

      final start = DateTime(
        day.year,
        day.month,
        day.day,
        _appUpdatePromptStartHour,
      );
      final end = DateTime(
        day.year,
        day.month,
        day.day,
        _appUpdatePromptEndHour,
      ).subtract(reserveBeforeEnd);

      if (dayOffset == 0) {
        if (from.isBefore(start)) return start;
        if (from.isBefore(end)) return from;
        continue;
      }
      return start;
    }

    return DateTime(
      from.year,
      from.month,
      from.day + 14,
      _appUpdatePromptStartHour,
    );
  }

  Future<void> _checkAppVersionPeriodicImpl() async {
    if (kDebugMode) return;
    try {
      final preferences = ensureLocalPreferenceRepository();
      final now = DateTime.now();
      final nextWindow = _nextAppUpdatePromptWindowStartImpl(now);
      if (nextWindow.isAfter(now)) {
        debugPrint(
          '[AppUpdateCheck] action=skip_check reason=outside_window '
          'next=${nextWindow.toIso8601String()}',
        );
        return;
      }

      final lastCheckedMs =
          await preferences.getInt(_appVersionLastCheckedAtKey) ?? 0;
      if (lastCheckedMs > 0) {
        final lastChecked = DateTime.fromMillisecondsSinceEpoch(lastCheckedMs);
        final alreadyCheckedToday = lastChecked.year == now.year &&
            lastChecked.month == now.month &&
            lastChecked.day == now.day;
        if (alreadyCheckedToday) {
          debugPrint(
            '[AppUpdateCheck] source=cache reason=allowed_day_gate',
          );
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

  String _appUpdateRatingShownAtKeyImpl(String updateKey) =>
      '$_appUpdateRatingShownAtKeyPrefix:$updateKey';

  String _appUpdateDialogDueAtKeyImpl(String updateKey) =>
      '$_appUpdateDialogDueAtKeyPrefix:$updateKey';

  void _handleRequiredAppUpdateImpl({
    required String requiredVersion,
    required int requiredBuild,
  }) {
    if (_isDisposed || _appUpdateFlowInFlight) return;
    _appUpdateFlowInFlight = true;
    unawaited(() async {
      try {
        await _runRequiredAppUpdateFlowImpl(
          requiredVersion: requiredVersion,
          requiredBuild: requiredBuild,
        );
      } finally {
        _appUpdateFlowInFlight = false;
      }
    }());
  }

  Future<void> _runRequiredAppUpdateFlowImpl({
    required String requiredVersion,
    required int requiredBuild,
  }) async {
    final preferences = ensureLocalPreferenceRepository();
    final updateKey = _appUpdatePromptCountKeyImpl(
      requiredVersion: requiredVersion,
      requiredBuild: requiredBuild,
    );
    final ratingShownKey = _appUpdateRatingShownAtKeyImpl(updateKey);
    final dialogDueKey = _appUpdateDialogDueAtKeyImpl(updateKey);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final ratingShownAtMs = await preferences.getInt(ratingShownKey) ?? 0;
    final dialogDueAtMs = await preferences.getInt(dialogDueKey) ?? 0;

    if (_ratingPromptEnabled && ratingShownAtMs <= 0) {
      final now = DateTime.now();
      final nextRatingWindow = _nextAppUpdatePromptWindowStartImpl(
        now,
        reserveBeforeEnd: _ratingPromptBeforeUpdateLead,
      );
      if (nextRatingWindow.isAfter(now)) {
        _scheduleRequiredAppUpdateRetryImpl(
          requiredVersion: requiredVersion,
          requiredBuild: requiredBuild,
          delay: nextRatingWindow.difference(now),
          reason: 'outside_rating_window',
        );
        return;
      }

      final didShowRating = await _showRatingPromptBeforeUpdateImpl(
        preferences: preferences,
        ratingShownKey: ratingShownKey,
        dialogDueKey: dialogDueKey,
        requiredVersion: requiredVersion,
        requiredBuild: requiredBuild,
      );
      if (!didShowRating) {
        _scheduleRequiredAppUpdateRetryImpl(
          requiredVersion: requiredVersion,
          requiredBuild: requiredBuild,
          delay: const Duration(seconds: 30),
          reason: 'rating_not_ready',
        );
      }
      return;
    }

    if (dialogDueAtMs > nowMs) {
      _scheduleUpdateDialogImpl(
        Duration(milliseconds: dialogDueAtMs - nowMs),
        requiredVersion: requiredVersion,
        requiredBuild: requiredBuild,
        reason: 'rating_lead_pending',
      );
      return;
    }

    _showUpdateDialogImpl(
      requiredVersion: requiredVersion,
      requiredBuild: requiredBuild,
    );
  }

  Future<bool> _showRatingPromptBeforeUpdateImpl({
    required LocalPreferenceRepository preferences,
    required String ratingShownKey,
    required String dialogDueKey,
    required String requiredVersion,
    required int requiredBuild,
  }) async {
    for (var attempt = 0; attempt < 48; attempt++) {
      if (_isDisposed || _ratingSheetShownThisSession) return false;
      final routeReady = Get.currentRoute.isEmpty ||
          Get.currentRoute == '/NavBarView' ||
          Get.currentRoute.contains('NavBar');
      final feedReady = selectedIndex.value == 0;
      final overlayFree =
          Get.isBottomSheetOpen != true && Get.isDialogOpen != true;
      if (Get.context != null && routeReady && feedReady && overlayFree) {
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (_isDisposed || Get.isDialogOpen == true) return false;
        final displayNow = DateTime.now();
        final nextRatingWindow = _nextAppUpdatePromptWindowStartImpl(
          displayNow,
          reserveBeforeEnd: _ratingPromptBeforeUpdateLead,
        );
        if (nextRatingWindow.isAfter(displayNow)) {
          _scheduleRequiredAppUpdateRetryImpl(
            requiredVersion: requiredVersion,
            requiredBuild: requiredBuild,
            delay: nextRatingWindow.difference(displayNow),
            reason: 'rating_window_closed_before_show',
          );
          return true;
        }

        final nowMs = displayNow.millisecondsSinceEpoch;
        final dueAtMs = nowMs + _ratingPromptBeforeUpdateLead.inMilliseconds;
        await preferences.setInt(ratingShownKey, nowMs);
        await preferences.setInt(dialogDueKey, dueAtMs);
        _scheduleUpdateDialogImpl(
          _ratingPromptBeforeUpdateLead,
          requiredVersion: requiredVersion,
          requiredBuild: requiredBuild,
          reason: 'after_rating_prompt',
        );
        debugPrint(
          '[RatingPrompt] action=show_before_update '
          'updateInMs=${_ratingPromptBeforeUpdateLead.inMilliseconds} '
          'attempt=$attempt',
        );
        await _maybeShowRatingPromptImpl(force: true);
        return true;
      }
      if (attempt == 0 || attempt % 8 == 0) {
        debugPrint(
          '[RatingPrompt] action=defer_before_update attempt=$attempt '
          'route=${Get.currentRoute} feedReady=$feedReady '
          'overlayFree=$overlayFree',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    debugPrint('[RatingPrompt] action=skip_before_update reason=not_ready');
    return false;
  }

  void _scheduleRequiredAppUpdateRetryImpl({
    required String requiredVersion,
    required int requiredBuild,
    required Duration delay,
    required String reason,
  }) {
    _updateDialogTimer?.cancel();
    final safeDelay = delay.isNegative ? Duration.zero : delay;
    debugPrint(
      '[AppUpdateCheck] action=schedule_update_flow_retry reason=$reason '
      'delayMs=${safeDelay.inMilliseconds}',
    );
    _updateDialogTimer = Timer(safeDelay, () {
      if (_isDisposed) return;
      _handleRequiredAppUpdateImpl(
        requiredVersion: requiredVersion,
        requiredBuild: requiredBuild,
      );
    });
  }

  void _scheduleUpdateDialogImpl(
    Duration delay, {
    required String requiredVersion,
    required int requiredBuild,
    required String reason,
  }) {
    _updateDialogTimer?.cancel();
    final safeDelay = delay.isNegative ? Duration.zero : delay;
    debugPrint(
      '[AppUpdateCheck] action=schedule_update_dialog reason=$reason '
      'delayMs=${safeDelay.inMilliseconds}',
    );
    if (safeDelay == Duration.zero) {
      _showUpdateDialogImpl(
        requiredVersion: requiredVersion,
        requiredBuild: requiredBuild,
      );
      return;
    }
    _updateDialogTimer = Timer(safeDelay, () {
      if (_isDisposed) return;
      _showUpdateDialogImpl(
        requiredVersion: requiredVersion,
        requiredBuild: requiredBuild,
      );
    });
  }

  void _showUpdateDialogImpl({
    required String requiredVersion,
    required int requiredBuild,
  }) {
    if (_isForceUpdateVisible) return;
    final now = DateTime.now();
    final nextWindow = _nextAppUpdatePromptWindowStartImpl(now);
    if (nextWindow.isAfter(now)) {
      _scheduleUpdateDialogImpl(
        nextWindow.difference(now),
        requiredVersion: requiredVersion,
        requiredBuild: requiredBuild,
        reason: 'outside_update_window',
      );
      return;
    }
    _isForceUpdateVisible = true;
    unawaited(() async {
      try {
        final preferences = ensureLocalPreferenceRepository();
        final countKey = _appUpdatePromptCountKeyImpl(
          requiredVersion: requiredVersion,
          requiredBuild: requiredBuild,
        );
        final showCount = (await preferences.getInt(countKey) ?? 0) + 1;
        await preferences.setInt(countKey, showCount);
        final forceUpdate = showCount >= 5;

        for (var attempt = 0; attempt < 48; attempt++) {
          if (_isDisposed) return;
          final routeReady = Get.currentRoute.isEmpty ||
              Get.currentRoute == '/NavBarView' ||
              Get.currentRoute.contains('NavBar');
          final feedReady = selectedIndex.value == 0;
          final overlayFree =
              Get.isBottomSheetOpen != true && Get.isDialogOpen != true;
          if (Get.context != null && routeReady && feedReady && overlayFree) {
            await WidgetsBinding.instance.endOfFrame;
            await Future<void>.delayed(const Duration(milliseconds: 350));
            if (_isDisposed || Get.isDialogOpen == true) return;
            debugPrint(
              '[AppUpdateCheck] action=show_update_dialog count=$showCount '
              'force=$forceUpdate key=$countKey attempt=$attempt',
            );
            await Get.dialog<void>(
              CupertinoAlertDialog(
                title: Text(
                  _updateTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _updateBody,
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                      color: Colors.black,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                actions: [
                  if (!forceUpdate)
                    CupertinoDialogAction(
                      onPressed: Get.back<void>,
                      child: const Text(
                        'Sonra',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: "Montserrat",
                          color: Colors.black,
                        ),
                      ),
                    ),
                  CupertinoDialogAction(
                    onPressed: _launchStore,
                    isDefaultAction: true,
                    child: Text(
                      'app_update.cta'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: "Montserrat",
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                ],
              ),
              barrierColor: Colors.black54,
              barrierDismissible: !forceUpdate,
            );
            return;
          }
          if (attempt == 0 || attempt % 8 == 0) {
            debugPrint(
              '[AppUpdateCheck] action=defer_update_dialog attempt=$attempt '
              'route=${Get.currentRoute} feedReady=$feedReady '
              'overlayFree=$overlayFree',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        debugPrint(
            '[AppUpdateCheck] action=skip_update_dialog reason=not_ready');
      } finally {
        _isForceUpdateVisible = false;
      }
    }());
  }

  void _scheduleRatingPromptImpl(
    Duration delay, {
    bool force = false,
  }) {
    _ratingPromptTimer?.cancel();
    _ratingPromptTimer = Timer(delay, () {
      if (_isDisposed) return;
      unawaited(_maybeShowRatingPromptImpl(force: force));
    });
  }

  Future<void> _maybeShowRatingPromptImpl({bool force = false}) async {
    if (_isDisposed ||
        _isForceUpdateVisible ||
        _ratingSheetShownThisSession ||
        (!force && selectedIndex.value != 0)) {
      return;
    }
    if (!force) {
      await _loadAppVersionConfigImpl(forceRefresh: false);
    }
    if (!_ratingPromptEnabled && !force) {
      return;
    }
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
      _scheduleRatingPromptImpl(
        force ? const Duration(seconds: 3) : const Duration(seconds: 45),
        force: force,
      );
      return;
    }

    final preferences = ensureLocalPreferenceRepository();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final firstSeenMs = await preferences.getInt(_ratingFirstSeenAtKey) ?? 0;
    final lastShownMs = await preferences.getInt(_ratingLastShownAtKey) ?? 0;
    final lastStoreTapMs =
        await preferences.getInt(_ratingLastStoreTapAtKey) ?? 0;

    if (!force && firstSeenMs <= 0) {
      await preferences.setInt(_ratingFirstSeenAtKey, nowMs);
      return;
    }

    if (!force) {
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
    }

    _ratingSheetShownThisSession = true;
    if (!force) {
      await preferences.setInt(_ratingLastShownAtKey, nowMs);
    }

    await Get.dialog<void>(
      CupertinoAlertDialog(
        title: Text(
          'nav.rating_prompt_title'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: "MontserratBold",
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (_) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.5),
                    child: Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFC107),
                      size: 27,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'nav.rating_prompt_body'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                  color: Colors.black,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: Get.back<void>,
            child: const Text(
              'Sonra',
              style: TextStyle(
                fontSize: 15,
                fontFamily: "Montserrat",
                color: Colors.black,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              await preferences.setInt(
                _ratingLastStoreTapAtKey,
                nowMs,
              );
              if (Get.isDialogOpen == true) {
                Get.back<void>();
              }
              await _launchStoreImpl();
            },
            isDefaultAction: true,
            child: const Text(
              'Değerlendir',
              style: TextStyle(
                fontSize: 15,
                fontFamily: "Montserrat",
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ),
        ],
      ),
      barrierColor: Colors.black54,
      barrierDismissible: true,
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
        final opened = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          AppSnackbar(
            'common.error'.tr,
            'nav.store_open_failed'.tr,
            backgroundColor: Colors.red.withValues(alpha: 0.7),
          );
        }
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
