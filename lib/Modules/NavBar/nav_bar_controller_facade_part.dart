part of 'nav_bar_controller.dart';

const String _appVersionDocId = 'appVersion';
const String _selectedIndexPrefKeyPrefix = 'nav_selected_index';
const String _ratingFirstSeenAtKey = 'rating_prompt_first_seen_at';
const String _ratingLastShownAtKey = 'rating_prompt_last_shown_at';
const String _ratingLastStoreTapAtKey = 'rating_prompt_last_store_tap_at';

NavBarController ensureNavBarController() => _ensureNavBarController();

NavBarController? maybeFindNavBarController() => _maybeFindNavBarController();

NavBarController _ensureNavBarController() =>
    _maybeFindNavBarController() ?? Get.put(NavBarController(), permanent: true);

NavBarController? _maybeFindNavBarController() =>
    Get.isRegistered<NavBarController>() ? Get.find<NavBarController>() : null;

extension NavBarControllerFacadePart on NavBarController {
  void changeIndex(int index) => _changeIndexImpl(index);

  void pauseGlobalTabMedia() => _pauseGlobalTabMediaImpl();

  void suspendFeedForTabExit() => _suspendFeedForTabExitImpl();

  void resumeFeedIfNeeded() => _resumeFeedIfNeededImpl();

  void pushMediaOverlayLock() => _pushMediaOverlayLockImpl();

  void popMediaOverlayLock() => _popMediaOverlayLockImpl();
}
