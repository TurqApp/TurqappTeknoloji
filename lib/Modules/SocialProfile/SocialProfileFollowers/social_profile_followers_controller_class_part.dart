part of 'social_profile_followers_controller.dart';

class SocialProfileFollowersController extends GetxController {
  final _state = _SocialProfileFollowersControllerState();
  static const Duration _relationCacheTtl = Duration(seconds: 30);
  static const Duration _relationCacheStaleRetention = Duration(minutes: 3);
  static const int _maxRelationCacheEntries = 400;
  static final Map<String, _RelationListCacheEntry> _relationCache =
      <String, _RelationListCacheEntry>{};

  static SocialProfileFollowersController ensure({
    required int initialPage,
    required String userID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureSocialProfileFollowersController(
        initialPage: initialPage,
        userID: userID,
        tag: tag,
        permanent: permanent,
      );

  static SocialProfileFollowersController? maybeFind({String? tag}) =>
      _maybeFindSocialProfileFollowersController(tag: tag);

  SocialProfileFollowersController({
    required int initialPage,
    required String userID,
  }) {
    this.userID = userID;
    selection.value = initialPage;
    pageController = PageController(initialPage: initialPage);
  }

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
