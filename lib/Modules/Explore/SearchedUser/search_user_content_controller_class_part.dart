part of 'search_user_content_controller.dart';

class SearchUserContentController extends GetxController {
  final _SearchUserContentControllerState _state;

  SearchUserContentController({required String userID})
      : _state = _SearchUserContentControllerState(userID: userID);

  Future<void> goToProfile() => _goToSearchUserProfile(this);

  Future<void> removeFromLastSearch() => _removeFromSearchUserLastSearch(this);
}
