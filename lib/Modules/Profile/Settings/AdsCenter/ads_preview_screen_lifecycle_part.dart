part of 'ads_preview_screen.dart';

extension AdsPreviewScreenLifecyclePart on _AdsPreviewScreenState {
  void _initLifecycle() {
    _controller = AdsCenterController.ensure();
    _userId.text = _currentUid;
  }

  void _disposeLifecycle() {
    _country.dispose();
    _city.dispose();
    _age.dispose();
    _userId.dispose();
  }
}
