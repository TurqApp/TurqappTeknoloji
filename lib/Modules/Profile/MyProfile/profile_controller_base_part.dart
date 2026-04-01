part of 'profile_controller.dart';

abstract class _ProfileControllerBase extends GetxController {
  final _lifecycleState = _ProfileLifecycleState();
  final _scrollState = _ProfileScrollState();
  final _headerState = _ProfileHeaderState();
  final _feedState = _ProfileFeedState();

  @override
  void onInit() {
    super.onInit();
    (this as ProfileController)._performOnInit();
  }

  @override
  void onClose() {
    (this as ProfileController)._performOnClose();
    super.onClose();
  }
}
