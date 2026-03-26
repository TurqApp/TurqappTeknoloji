part of 'profile_controller.dart';

class ProfileController extends GetxController {
  static ProfileController ensure() =>
      maybeFind() ?? Get.put(ProfileController());

  static ProfileController? maybeFind() => Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : null;

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
