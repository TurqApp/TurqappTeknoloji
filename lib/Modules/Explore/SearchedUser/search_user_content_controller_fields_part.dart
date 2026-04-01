part of 'search_user_content_controller.dart';

class _SearchUserContentControllerState {
  _SearchUserContentControllerState({required this.userID});

  final UserSubcollectionRepository userSubcollectionRepository =
      ensureUserSubcollectionRepository();
  final String userID;
  final RxBool isNavigated = false.obs;
}

class SearchUserContentController extends GetxController {
  final _SearchUserContentControllerState _state;

  SearchUserContentController({required String userID})
      : _state = _SearchUserContentControllerState(userID: userID);

  Future<void> goToProfile() => _goToSearchUserProfile(this);

  Future<void> removeFromLastSearch() => _removeFromSearchUserLastSearch(this);
}

extension SearchUserContentControllerFieldsPart on SearchUserContentController {
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
  String get userID => _state.userID;
  RxBool get isNavigated => _state.isNavigated;
}
