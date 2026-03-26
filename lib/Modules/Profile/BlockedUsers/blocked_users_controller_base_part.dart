part of 'blocked_users_controller.dart';

abstract class _BlockedUsersControllerBase extends GetxController {
  final RxList<String> blockedUsers = <String>[].obs;
  final RxList<OgrenciModel> blockedUserDetails = <OgrenciModel>[].obs;
  final RxBool isLoading = true.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      ensureUserSubcollectionRepository();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    unawaited((this as BlockedUsersController)._handleOnInit());
  }
}
