part of 'nav_bar_controller.dart';

const String _appVersionDocId = 'appVersion';
const String _selectedIndexPrefKeyPrefix = 'nav_selected_index';
const String _appVersionLastCheckedAtKey = 'app_version_last_checked_at';
const String _appVersionPromptCountKeyPrefix = 'app_version_prompt_count';
const String _ratingFirstSeenAtKey = 'rating_prompt_first_seen_at';
const String _ratingLastShownAtKey = 'rating_prompt_last_shown_at';
const String _ratingLastStoreTapAtKey = 'rating_prompt_last_store_tap_at';
const String _appUpdateRatingShownAtKeyPrefix = 'app_update_rating_shown_at';
const String _appUpdateDialogDueAtKeyPrefix = 'app_update_dialog_due_at';
const Duration _ratingPromptBeforeUpdateLead = Duration(minutes: 15);
const int _appUpdatePromptStartHour = 9;
const int _appUpdatePromptEndHour = 23;
const Set<int> _appVersionCheckWeekdays = <int>{
  DateTime.wednesday,
  DateTime.saturday,
};

NavBarController ensureNavBarController() => _ensureNavBarController();

NavBarController? maybeFindNavBarController() => _maybeFindNavBarController();

NavBarController _ensureNavBarController() =>
    _maybeFindNavBarController() ??
    Get.put(NavBarController(), permanent: true);

NavBarController? _maybeFindNavBarController() =>
    Get.isRegistered<NavBarController>() ? Get.find<NavBarController>() : null;

extension NavBarControllerFacadePart on NavBarController {
  void changeIndex(int index) => _changeIndexImpl(index);

  void pauseGlobalTabMedia() => _pauseGlobalTabMediaImpl();

  void suspendFeedForTabExit() => _suspendFeedForTabExitImpl();

  void resumeFeedIfNeeded() => _resumeFeedIfNeededImpl();

  Future<void> checkAppVersionAfterFeedOpened() =>
      _checkAppVersionPeriodicImpl();

  void pushMediaOverlayLock() => _pushMediaOverlayLockImpl();

  void popMediaOverlayLock() => _popMediaOverlayLockImpl();

  void updateVisibilityFromPrimaryScroll({
    required String source,
    required double offset,
  }) =>
      _updateVisibilityFromPrimaryScrollImpl(source: source, offset: offset);

  void resetVisibilityScrollAnchor({
    required String source,
    double offset = 0,
  }) =>
      _resetVisibilityScrollAnchorImpl(source: source, offset: offset);

  void updateVisibilityFromGlobalSwipe({
    required String source,
    required double deltaY,
    required double deltaX,
  }) =>
      _updateVisibilityFromGlobalSwipeImpl(
        source: source,
        deltaY: deltaY,
        deltaX: deltaX,
      );
}
