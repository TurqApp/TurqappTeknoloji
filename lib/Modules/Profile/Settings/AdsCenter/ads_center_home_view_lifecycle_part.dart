part of 'ads_center_home_view.dart';

extension AdsCenterHomeViewLifecyclePart on _AdsCenterHomeViewState {
  void _initLifecycle() {
    _tabController = TabController(length: 6, vsync: this);
    final existingController = AdsCenterController.maybeFind();
    if (existingController != null) {
      _controller = existingController;
    } else {
      _controller = AdsCenterController.ensure();
      _ownsController = true;
    }
  }

  void _disposeLifecycle() {
    if (_ownsController &&
        identical(AdsCenterController.maybeFind(), _controller)) {
      Get.delete<AdsCenterController>(force: true);
    }
    _tabController.dispose();
  }
}
