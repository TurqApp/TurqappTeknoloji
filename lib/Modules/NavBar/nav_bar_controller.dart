import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

import '../Short/short_controller.dart';
import '../Agenda/agenda_controller.dart';
import '../Explore/explore_controller.dart';
import '../Education/education_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/audio_focus_coordinator.dart';
import '../../Core/Services/integration_test_mode.dart';
import '../../Core/Services/upload_queue_service.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Services/current_user_service.dart';
import '../Profile/Settings/settings_controller.dart';

typedef TextUpdate = String;

class NavBarController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  static NavBarController _ensureController() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NavBarController());
  }

  static NavBarController ensure() => _ensureController();

  static NavBarController? maybeFind() {
    if (!Get.isRegistered<NavBarController>()) return null;
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
    final uid = CurrentUserService.instance.userId;
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
    final uid = CurrentUserService.instance.userId;
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

  void _startBackgroundCacheLoop() {
    _backgroundCacheTimer?.cancel();
    _backgroundCacheTimer =
        Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_isDisposed) return;
      if (!ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed)) {
        return;
      }

      try {
        if (Get.isRegistered<AgendaController>()) {
          Get.find<AgendaController>().ensureFeedCacheWarm();
        }
      } catch (_) {}

      try {
        final shortsController = ShortController.maybeFind();
        if (shortsController != null && shortsController.shorts.length < 8) {
          shortsController.warmStart(targetCount: 8, maxPages: 2);
        }
      } catch (_) {}

      try {
        final storyController = StoryRowController.maybeFind();
        if (storyController != null && storyController.users.length < 30) {
          await storyController.loadStories(
            limit: 30,
            cacheFirst: true,
            silentLoad: true,
          );
        }
      } catch (_) {}
    });
  }

  void _startUploadIndicatorSync() {
    _uploadIndicatorTimer?.cancel();
    _uploadIndicatorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      if (!Get.isRegistered<UploadQueueService>()) {
        uploadingPosts.value = false;
        return;
      }
      final queue = Get.find<UploadQueueService>();
      final stats = queue.getQueueStats();
      final pending = (stats['pending'] as int?) ?? 0;
      final processing = (stats['processing'] as bool?) ?? false;
      uploadingPosts.value = processing || pending > 0;
    });
  }

  Future<void> _runAcilisAnimation() async {
    try {
      // ⚠️ CRITICAL FIX: Check if controller is still alive before animating
      if (!_isDisposed) {
        await typingController.value.forward();
      }
      if (!_isDisposed) {
        await Future.delayed(const Duration(seconds: 1));
      }
      if (!_isDisposed) {
        await deletingController.value.forward();
      }
      if (!_isDisposed) {
        hideAcilis.value = true;
      }
    } catch (_) {
      // Animation was interrupted (controller disposed), silently ignore
    }
  }

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    final hasEducation =
        SettingsController.maybeFind()?.educationScreenIsOn.value ?? false;
    final educationIndex = hasEducation ? 3 : -1;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}
      try {
        AudioFocusCoordinator.instance.pauseAllAudioPlayers();
      } catch (_) {}
      return;
    }

    if (state == AppLifecycleState.resumed && selectedIndex.value == 0) {
      if (!IntegrationTestMode.suppressPeriodicSideEffects) {
        unawaited(checkAppVersion());
        _scheduleRatingPrompt(const Duration(seconds: 12));
      }
      try {
        if (Get.isRegistered<AgendaController>()) {
          Get.find<AgendaController>().resumeFeedPlayback();
        }
      } catch (_) {}
    }
    if (state == AppLifecycleState.resumed &&
        educationIndex >= 0 &&
        selectedIndex.value == educationIndex) {
      try {
        if (Get.isRegistered<EducationController>()) {
          Get.find<EducationController>().resetActivePasajSurfaceToTop();
        }
      } catch (_) {}
    }
  }

  void changeIndex(int index) {
    final previous = selectedIndex.value;
    final hasEducation =
        SettingsController.maybeFind()?.educationScreenIsOn.value ?? false;
    final educationIndex = hasEducation ? 3 : -1;
    selectedIndex.value = index;
    unawaited(_persistSelectedIndex(index));

    // Feed dışında bir sekmeye geçildiğinde medya seslerini her durumda sustur.
    // (Sadece previous==0 kontrolü bazı hızlı geçişlerde kaçırabiliyordu.)
    if (index != 0) {
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}
      try {
        AudioFocusCoordinator.instance.pauseAllAudioPlayers();
      } catch (_) {}
    }

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        try {
          if (Get.isRegistered<AgendaController>()) {
            Get.find<AgendaController>().resumeFeedPlayback();
          }
        } catch (_) {}
      });
    }

    if (educationIndex >= 0 && index == educationIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        try {
          if (Get.isRegistered<EducationController>()) {
            Get.find<EducationController>().resetActivePasajSurfaceToTop();
          }
        } catch (_) {}
      });
    }

    if (previous == 1 && index != 1) {
      // Keşfet'ten çıkarken resetle; geri dönünce Gündem ile açılır.
      ExploreController.maybeFind()?.resetSearchToDefault();
    }
  }

  Future<void> ensureProactiveShortPreloadStarted() async {
    if (_proactiveShortPreloadStarted) return;
    _proactiveShortPreloadStarted = true;
    try {
      await shortCtrl.backgroundPreload();
    } catch (_) {}
  }

  Future<void> _loadAppVersionConfig({bool forceRefresh = false}) async {
    final repo = ConfigRepository.ensure();
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

    _androidMinVersion = (doc['androidMinVersion'] ?? '').toString().trim();
    _iosMinVersion = (doc['iosMinVersion'] ?? '').toString().trim();

    final updateTitle = (doc['updateTitle'] ?? '').toString().trim();
    final updateBody = (doc['updateBody'] ?? '').toString().trim();
    _updateTitle = updateTitle.isEmpty ? 'app_update.title'.tr : updateTitle;
    _updateBody = updateBody.isEmpty ? 'app_update.body'.tr : updateBody;

    final androidStoreUrl = (doc['androidStoreUrl'] ?? '').toString().trim();
    final iosStoreUrl = (doc['iosStoreUrl'] ?? '').toString().trim();
    _androidStoreUrlOverride = androidStoreUrl.isEmpty ? null : androidStoreUrl;
    _iosStoreUrlOverride = iosStoreUrl.isEmpty ? null : iosStoreUrl;

    _ratingPromptEnabled = doc['ratingPromptEnabled'] != false;
    final initialDays =
        (doc['ratingPromptInitialDelayDays'] as num?)?.toInt() ?? 7;
    final repeatDays = (doc['ratingPromptRepeatDays'] as num?)?.toInt() ?? 7;
    final cooldownDays =
        (doc['ratingPromptStoreCooldownDays'] as num?)?.toInt() ?? 90;
    _ratingPromptEnabledAfter =
        Duration(days: initialDays < 1 ? 7 : initialDays);
    _ratingPromptRepeatAfter = Duration(days: repeatDays < 1 ? 7 : repeatDays);
    _ratingPromptStoreCooldown =
        Duration(days: cooldownDays < 1 ? 90 : cooldownDays);
  }

  Future<void> checkAppVersion() async {
    try {
      // Debug modda version kontrolünü bypass et
      if (kDebugMode) {
        return;
      }

      // Mevcut uygulama bilgilerini al
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      await _loadAppVersionConfig(forceRefresh: true);

      String requiredVersion = "";
      if (Platform.isAndroid) {
        requiredVersion = _androidMinVersion;
      } else if (Platform.isIOS) {
        requiredVersion = _iosMinVersion;
      }

      // Version karşılaştırması yap
      if (requiredVersion.isNotEmpty &&
          _isVersionLower(currentVersion, requiredVersion)) {
        _showUpdateDialog();
      }
    } catch (_) {
      // Fail-open: ağ/izin/Firestore hatasında kullanıcıyı kilitleme.
    }
  }

  bool _isVersionLower(String currentVersion, String requiredVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> required = requiredVersion.split('.').map(int.parse).toList();

    // Version numaralarını karşılaştır
    for (int i = 0; i < 3; i++) {
      int currentPart = i < current.length ? current[i] : 0;
      int requiredPart = i < required.length ? required[i] : 0;

      if (currentPart < requiredPart) return true;
      if (currentPart > requiredPart) return false;
    }

    return false; // Eşit version
  }

  void _showUpdateDialog() {
    if (_isForceUpdateVisible) return;
    _isForceUpdateVisible = true;
    Get.bottomSheet(
      isDismissible: false,
      enableDrag: false,
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
              // Handle çubuğu
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Güncelleme ikonu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container(
                  //   width: 80,
                  //   height: 80,
                  //   decoration: BoxDecoration(
                  //     color: Colors.blue.withValues(alpha: 0.1),
                  //     borderRadius: BorderRadius.circular(40),
                  //   ),
                  //   child: const Icon(
                  //     Icons.system_update,
                  //     size: 40,
                  //     color: Colors.blue,
                  //   ),
                  // ),
                  // 12.pw,
                  Image.asset(
                    "assets/logo/logo.webp",
                    color: Colors.black,
                    height: 80,
                    width: 80,
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Başlık
              Text(
                _updateTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "MontserratBold",
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Açıklama
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
                    style: TextStyle(
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Daha sonra butonu
              // SizedBox(
              //   width: double.infinity,
              //   height: 50,
              //   child: TextButton(
              //     onPressed: () => Get.back(),
              //     child: const Text(
              //       "Daha Sonra",
              //       style: TextStyle(
              //         fontSize: 16,
              //         color: Colors.grey,
              //         fontFamily: "MontserratMedium",
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleRatingPrompt(Duration delay) {
    _ratingPromptTimer?.cancel();
    _ratingPromptTimer = Timer(delay, () {
      if (_isDisposed) return;
      unawaited(_maybeShowRatingPrompt());
    });
  }

  Future<void> _maybeShowRatingPrompt() async {
    if (_isDisposed ||
        _isForceUpdateVisible ||
        _ratingSheetShownThisSession ||
        selectedIndex.value != 0) {
      return;
    }
    await _loadAppVersionConfig(forceRefresh: false);
    if (!_ratingPromptEnabled) {
      return;
    }
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
      _scheduleRatingPrompt(const Duration(seconds: 45));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final firstSeenMs = prefs.getInt(_ratingFirstSeenAtKey) ?? 0;
    final lastShownMs = prefs.getInt(_ratingLastShownAtKey) ?? 0;
    final lastStoreTapMs = prefs.getInt(_ratingLastStoreTapAtKey) ?? 0;

    if (firstSeenMs <= 0) {
      await prefs.setInt(_ratingFirstSeenAtKey, nowMs);
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
    await prefs.setInt(_ratingLastShownAtKey, nowMs);

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
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontFamily: 'MontserratBold',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'nav.rating_prompt_body'.tr,
                style: TextStyle(
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
                    await prefs.setInt(_ratingLastStoreTapAtKey, nowMs);
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                    await _launchStore();
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
                    style: TextStyle(
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
                    style: TextStyle(
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

  Future<void> _launchStore() async {
    String storeUrl = "";

    if (Platform.isAndroid) {
      storeUrl = _androidStoreUrlOverride ??
          "https://play.google.com/store/apps/details?id=com.turqapp.app";
    } else if (Platform.isIOS) {
      storeUrl = _iosStoreUrlOverride ??
          "https://apps.apple.com/tr/app/turqapp/id6740809479?l=tr";
    }

    if (storeUrl.isNotEmpty) {
      final Uri url = Uri.parse(storeUrl);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
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
