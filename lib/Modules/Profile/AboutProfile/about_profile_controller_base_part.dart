part of 'about_profile_controller.dart';

abstract class _AboutProfileControllerBase extends GetxController {
  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  String get _currentUid => userService.effectiveUserId;

  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final fullName = ''.obs;
  final createdDate = ''.obs;
  String? _loadedUserId;
  Future<void>? _pendingLoad;
}
