part of 'profile_view.dart';

extension _ProfileViewProfilePart on _ProfileViewState {
  String get _myUserId => userService.effectiveUserId;

  String get _myNickname => userService.nickname;

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

  String get _myFirstName => userService.firstName;

  String get _myLastName => userService.lastName;

  bool get _hasVerifiedRozet {
    final headerRozet = normalizeRozetValue(controller.headerRozet.value);
    if (headerRozet.isNotEmpty) return true;
    return normalizeRozetValue(userService.rozet).isNotEmpty;
  }

  String get _myMeslek => userService.meslekKategori;

  String get _myBio => userService.bio;

  String get _myAdres => userService.adres;

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

  int get _myTotalPosts => userService.counterOfPosts;

  int get _myTotalLikes => userService.counterOfLikes;

  int get _myTotalMarket =>
      _marketItems.where((item) => item.status != 'archived').length;

  bool get _hasMyStories =>
      _myUserId.isNotEmpty &&
      storyOwnerUsers
          .any((user) => user.userID == _myUserId && user.stories.isNotEmpty);

  List<StoryUserModel> get storyOwnerUsers {
    final rowController = StoryRowController.maybeFind();
    if (rowController == null) {
      return const <StoryUserModel>[];
    }
    return rowController.users;
  }

  StoryHighlightsController? _ensureProfileHighlightsController() {
    final uid = _myUserId.trim();
    if (uid.isEmpty) return null;
    final tag = 'highlights_$uid';
    final existing = StoryHighlightsController.maybeFind(tag: tag);
    if (existing != null) {
      return existing;
    }
    _ownsHighlightsController = true;
    return StoryHighlightsController.ensure(userId: uid, tag: tag);
  }

  Future<void> _refreshProfileSurfaceMeta({bool force = false}) async {
    final uid = _myUserId.trim();
    if (uid.isEmpty) return;
    await controller.refreshAll(forceSync: force);
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
