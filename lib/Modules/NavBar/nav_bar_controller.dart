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
part 'nav_bar_controller_support_part.dart';
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

  Future<void> restorePersistedIndex() =>
      _NavBarControllerSupportPart(this).restorePersistedIndex();

  Future<void> _persistSelectedIndex(int index) =>
      _NavBarControllerSupportPart(this).persistSelectedIndex(index);

  @override
  void onInit() {
    super.onInit();
    _NavBarControllerSupportPart(this).handleOnInit();
  }

  void _startBackgroundCacheLoop() => _startBackgroundCacheLoopImpl();

  void _startUploadIndicatorSync() => _startUploadIndicatorSyncImpl();

  Future<void> _runAcilisAnimation() => _runAcilisAnimationImpl();

  @override
  void onClose() {
    _NavBarControllerSupportPart(this).handleOnClose();
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
