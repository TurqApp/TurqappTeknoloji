part of 'about_profile_controller.dart';

class AboutProfileController extends GetxController {
  static AboutProfileController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AboutProfileController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static AboutProfileController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AboutProfileController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AboutProfileController>(tag: tag);
  }

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
