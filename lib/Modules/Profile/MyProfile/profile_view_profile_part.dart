part of 'profile_view.dart';

extension _ProfileViewProfilePart on _ProfileViewState {
  CurrentUserModel? get _reactiveCurrentUser => userService.currentUserRx.value;

  String get _myUserId {
    final cached = (_reactiveCurrentUser?.userID ?? '').trim();
    if (cached.isNotEmpty) return cached;
    return userService.effectiveUserId;
  }

  String get _myNickname =>
      _reactiveCurrentUser?.nickname ?? userService.nickname;

  String get _myIosSafeNickname {
    final controllerNickname = controller.headerNickname.value.trim();
    if (controllerNickname.isNotEmpty) return controllerNickname;
    final direct = _myNickname.trim();
    if (direct.isNotEmpty) return direct;
    return _myNickname;
  }

  String get _myAvatarUrl {
    final direct = controller.headerAvatarUrl.value.trim();
    if (direct.isNotEmpty) return direct;
    return userService.avatarUrl;
  }

  String get _myFirstName =>
      _reactiveCurrentUser?.firstName ?? userService.firstName;

  String get _myLastName =>
      _reactiveCurrentUser?.lastName ?? userService.lastName;

  bool get _hasVerifiedRozet {
    final headerRozet = normalizeRozetValue(controller.headerRozet.value);
    if (headerRozet.isNotEmpty) return true;
    return normalizeRozetValue(userService.rozet).isNotEmpty;
  }

  String get _myMeslek =>
      _reactiveCurrentUser?.meslekKategori ?? userService.meslekKategori;

  String get _myBio => _reactiveCurrentUser?.bio ?? userService.bio;

  String get _myAdres => _reactiveCurrentUser?.adres ?? userService.adres;

  String get _myDisplayFirstName {
    final display = controller.headerDisplayName.value.trim();
    if (display.isNotEmpty) return display;
    final direct = controller.headerFirstName.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myFirstName.trim();
  }

  String get _myDisplayLastName {
    if (controller.headerDisplayName.value.trim().isNotEmpty) return '';
    final direct = controller.headerLastName.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myLastName.trim();
  }

  String get _myDisplayMeslek {
    final direct = controller.headerMeslek.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myMeslek.trim();
  }

  String get _myDisplayBio {
    final direct = controller.headerBio.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myBio.trim();
  }

  String get _myDisplayAdres {
    final direct = controller.headerAdres.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myAdres.trim();
  }

  int get _myTotalPosts =>
      _reactiveCurrentUser?.counterOfPosts ?? userService.counterOfPosts;

  int get _myTotalLikes =>
      _reactiveCurrentUser?.counterOfLikes ?? userService.counterOfLikes;

  int get _myTotalMarket =>
      controller.listingCount.value > 0
          ? controller.listingCount.value
          : _marketItems.where((item) => item.status != 'archived').length;

  bool get _hasMyStories =>
      _myUserId.isNotEmpty &&
      storyOwnerUsers
          .any((user) => user.userID == _myUserId && user.stories.isNotEmpty);

  List<StoryUserModel> get storyOwnerUsers {
    final rowController = maybeFindStoryRowController();
    if (rowController == null) {
      return const <StoryUserModel>[];
    }
    return rowController.users;
  }

  StoryHighlightsController? _ensureProfileHighlightsController() {
    final uid = _myUserId.trim();
    if (uid.isEmpty) return null;
    final tag = 'highlights_$uid';
    final existing = maybeFindStoryHighlightsController(tag: tag);
    if (existing != null) {
      return existing;
    }
    _ownsHighlightsController = true;
    return ensureStoryHighlightsController(userId: uid, tag: tag);
  }

  Future<void> _refreshProfileSurfaceMeta({bool force = false}) async {
    if (!_isProfileSurfaceActive()) return;
    final uid = _myUserId.trim();
    if (uid.isEmpty) return;
    await controller.refreshAll(forceSync: force);
    await _refreshProfileSupplementalMeta(force: force);
  }

  Future<void> _refreshProfileSupplementalMeta({bool force = false}) async {
    if (!_isProfileSurfaceActive()) return;
    final uid = _myUserId.trim();
    if (uid.isEmpty) return;
    await socialMediaController.getData(
      silent: !force,
      forceRefresh: force,
    );
    final highlightsController = _ensureProfileHighlightsController();
    if (highlightsController != null) {
      await highlightsController.loadHighlights(
        silent: !force,
        forceRefresh: force,
      );
    }
    unawaited(_loadMarketItems(force: force));
  }
}
