part of 'blocked_users_controller.dart';

class BlockedUsersController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final RxList<String> blockedUsers = <String>[].obs;
  final RxList<OgrenciModel> blockedUserDetails = <OgrenciModel>[].obs;
  final RxBool isLoading = true.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
