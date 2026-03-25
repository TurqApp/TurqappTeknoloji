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
  static NavBarController ensure() =>
      maybeFind() ?? Get.put(NavBarController());

  static NavBarController? maybeFind() => Get.isRegistered<NavBarController>()
      ? Get.find<NavBarController>()
      : null;

  static const String _appVersionDocId = 'appVersion';
  static const String _selectedIndexPrefKeyPrefix = 'nav_selected_index';
  static const String _ratingFirstSeenAtKey = 'rating_prompt_first_seen_at';
  static const String _ratingLastShownAtKey = 'rating_prompt_last_shown_at';
  static const String _ratingLastStoreTapAtKey =
      'rating_prompt_last_store_tap_at';
  var selectedIndex = 0.obs, showBar = true.obs;
  ShortController? _shortCtrl;
  final String fullText = "TurqApp";

  ShortController get shortCtrl => _shortCtrl ??= ShortController.ensure();

  late final Rx<AnimationController> typingController,
      deletingController,
      animationController;
  var visibleCharCount = 0.obs, removeCharCount = 0.obs, hideAcilis = false.obs;
  final uploadingPosts = false.obs;

  bool _isDisposed = false,
      _isForceUpdateVisible = false,
      _ratingSheetShownThisSession = false;
  String _androidMinVersion = '', _iosMinVersion = '';
  String _updateTitle = 'app_update.title'.tr;
  String _updateBody = 'app_update.body'.tr;
  String? _androidStoreUrlOverride;
  String? _iosStoreUrlOverride;
  bool _ratingPromptEnabled = true;
  Duration _ratingPromptEnabledAfter = const Duration(days: 7);
  Duration _ratingPromptRepeatAfter = const Duration(days: 7);
  Duration _ratingPromptStoreCooldown = const Duration(days: 90);
  Timer? _backgroundCacheTimer, _uploadIndicatorTimer, _ratingPromptTimer;

  @override
  void onInit() {
    super.onInit();
    _NavBarControllerSupportPart(this).handleOnInit();
  }

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
}
