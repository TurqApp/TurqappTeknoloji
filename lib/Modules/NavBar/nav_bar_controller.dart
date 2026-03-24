import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

import '../Short/short_controller.dart';
import '../Agenda/agenda_controller.dart';
import '../Explore/explore_controller.dart';
import '../Education/education_controller.dart';
import '../Profile/MyProfile/profile_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/audio_focus_coordinator.dart';
import '../../Core/Services/integration_test_mode.dart';
import '../../Core/Services/upload_queue_service.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Services/current_user_service.dart';
import '../Profile/Settings/settings_controller.dart';

part 'nav_bar_controller_lifecycle_part.dart';
part 'nav_bar_controller_update_part.dart';

typedef TextUpdate = String;

class NavBarController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  static NavBarController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NavBarController());
  }

  static NavBarController? maybeFind() {
    final isRegistered = Get.isRegistered<NavBarController>();
    if (!isRegistered) return null;
    return Get.find<NavBarController>();
  }

  static const String _appVersionDocId = 'appVersion';
  static const String _selectedIndexPrefKeyPrefix = 'nav_selected_index';
  static const String _ratingFirstSeenAtKey = 'rating_prompt_first_seen_at';
  static const String _ratingLastShownAtKey = 'rating_prompt_last_shown_at';
  static const String _ratingLastStoreTapAtKey =
      'rating_prompt_last_store_tap_at';
  var selectedIndex = 0.obs;
  var showBar = true.obs;
  ShortController?
      _shortCtrl; // ⚠️ CRITICAL FIX: Make nullable for safe lazy init
  final String fullText = "TurqApp";

  // ⚠️ CRITICAL FIX: Safe getter for ShortController
  ShortController get shortCtrl => _shortCtrl ??= ShortController.ensure();

  late final Rx<AnimationController> typingController;
  late final Rx<AnimationController> deletingController;
  late final Rx<AnimationController> animationController;

  var visibleCharCount = 0.obs;
  var removeCharCount = 0.obs;
  var hideAcilis = false.obs;

  // Upload activity indicator for NavBar profile avatar
  final uploadingPosts = false.obs;

  // ⚠️ CRITICAL FIX: Track disposal state to prevent animation errors
  bool _isDisposed = false;
  bool _proactiveShortPreloadStarted = false;
  bool _isForceUpdateVisible = false;
  bool _ratingSheetShownThisSession = false;
  String _androidMinVersion = '';
  String _iosMinVersion = '';
  String _updateTitle = 'app_update.title'.tr;
  String _updateBody = 'app_update.body'.tr;
  String? _androidStoreUrlOverride;
  String? _iosStoreUrlOverride;
  bool _ratingPromptEnabled = true;
  Duration _ratingPromptEnabledAfter = const Duration(days: 7);
  Duration _ratingPromptRepeatAfter = const Duration(days: 7);
  Duration _ratingPromptStoreCooldown = const Duration(days: 90);
  Timer? _backgroundCacheTimer;
  Timer? _uploadIndicatorTimer;
  Timer? _ratingPromptTimer;

  String _selectedIndexKeyFor(String uid) =>
      '${_selectedIndexPrefKeyPrefix}_$uid';

  int _normalizeSelectedIndex(int value) {
    if (value == 2) return 0;
    if (value < 0) return 0;
    if (value > 4) return 4;
    return value;
  }

  Future<void> restorePersistedIndex() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_selectedIndexKeyFor(uid));
      if (stored == null) return;
      selectedIndex.value = _normalizeSelectedIndex(stored);
    } catch (_) {}
  }

  Future<void> _persistSelectedIndex(int index) async {
    if (index == 2) return;
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _selectedIndexKeyFor(uid),
        _normalizeSelectedIndex(index),
      );
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Animation Controllers
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    ).obs;
    animationController.value.repeat();

    typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    ).obs;
    typingController.value.addListener(() {
      visibleCharCount.value =
          (fullText.length * typingController.value.value).floor();
    });

    deletingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    ).obs;
    deletingController.value.addListener(() {
      removeCharCount.value =
          (deletingController.value.value * fullText.length).floor();
    });

    unawaited(restorePersistedIndex());
    _runAcilisAnimation();
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed && !IntegrationTestMode.suppressPeriodicSideEffects) {
        unawaited(checkAppVersion());
      }
    });
    if (!IntegrationTestMode.suppressPeriodicSideEffects) {
      _scheduleRatingPrompt(const Duration(seconds: 25));
    }

    if (!GetPlatform.isIOS &&
        !IntegrationTestMode.suppressPeriodicSideEffects) {
      _startBackgroundCacheLoop();
    }
    _startUploadIndicatorSync();
    // Baslangicta e-posta dogrulama popup'i kapali.
  }

  void _startBackgroundCacheLoop() => _startBackgroundCacheLoopImpl();

  void _startUploadIndicatorSync() => _startUploadIndicatorSyncImpl();

  Future<void> _runAcilisAnimation() => _runAcilisAnimationImpl();

  @override
  void onClose() {
    // ⚠️ CRITICAL FIX: Mark as disposed first to stop animations
    _isDisposed = true;

    _backgroundCacheTimer?.cancel();
    _backgroundCacheTimer = null;
    _uploadIndicatorTimer?.cancel();
    _uploadIndicatorTimer = null;
    _ratingPromptTimer?.cancel();
    _ratingPromptTimer = null;
    WidgetsBinding.instance.removeObserver(this);

    // Dispose animation controllers safely
    try {
      typingController.value.dispose();
    } catch (_) {}

    try {
      deletingController.value.dispose();
    } catch (_) {}

    try {
      animationController.value.dispose();
    } catch (_) {}

    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _didChangeAppLifecycleStateImpl(state);

  void changeIndex(int index) => _changeIndexImpl(index);

  void pauseGlobalTabMedia() => _pauseGlobalTabMediaImpl();

  void suspendFeedForTabExit() => _suspendFeedForTabExitImpl();

  void resumeFeedIfNeeded() => _resumeFeedIfNeededImpl();

  Future<void> ensureProactiveShortPreloadStarted() =>
      _ensureProactiveShortPreloadStartedImpl();

  Future<void> checkAppVersion() => _checkAppVersionImpl();

  void _scheduleRatingPrompt(Duration delay) =>
      _scheduleRatingPromptImpl(delay);

  Future<void> _launchStore() => _launchStoreImpl();
}
