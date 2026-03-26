part of 'nav_bar_controller.dart';

const String _appVersionDocId = 'appVersion';
const String _selectedIndexPrefKeyPrefix = 'nav_selected_index';
const String _ratingFirstSeenAtKey = 'rating_prompt_first_seen_at';
const String _ratingLastShownAtKey = 'rating_prompt_last_shown_at';
const String _ratingLastStoreTapAtKey = 'rating_prompt_last_store_tap_at';

NavBarController _ensureNavBarController() =>
    _maybeFindNavBarController() ?? Get.put(NavBarController());

NavBarController? _maybeFindNavBarController() =>
    Get.isRegistered<NavBarController>() ? Get.find<NavBarController>() : null;
