part of 'profile_controller.dart';

class ProfileController extends GetxController {
  static ProfileController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileController());
  }

  static ProfileController? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileController>();
    if (!isRegistered) return null;
    return Get.find<ProfileController>();
  }

  final _lifecycleState = _ProfileLifecycleState();
  final _scrollState = _ProfileScrollState();
  final _headerState = _ProfileHeaderState();
  final _feedState = _ProfileFeedState();

  @override
  void onInit() {
    super.onInit();
    _performOnInit();
  }

  @override
  void onClose() {
    _performOnClose();
    super.onClose();
  }
}
