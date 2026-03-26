part of 'profile_controller.dart';

abstract class _ProfileControllerBase extends GetxController {
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
