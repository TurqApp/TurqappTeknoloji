part of 'about_profile_controller.dart';

class AboutProfileController extends GetxController {
  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  String get _currentUid => userService.effectiveUserId;

  var avatarUrl = "".obs;
  var nickname = "".obs;
  var fullName = "".obs;
  var createdDate = "".obs;
  String? _loadedUserId;
  Future<void>? _pendingLoad;

  Future<void> getUserData(String userID) =>
      _loadAboutProfileUserData(this, userID);
}
