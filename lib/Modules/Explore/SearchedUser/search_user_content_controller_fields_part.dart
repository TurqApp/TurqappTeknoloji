part of 'search_user_content_controller.dart';

class _SearchUserContentControllerState {
  _SearchUserContentControllerState({required this.userID});

  final UserSubcollectionRepository userSubcollectionRepository =
      ensureUserSubcollectionRepository();
  final String userID;
  final RxBool isNavigated = false.obs;
}

extension SearchUserContentControllerFieldsPart on SearchUserContentController {
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
  String get userID => _state.userID;
  RxBool get isNavigated => _state.isNavigated;
}
