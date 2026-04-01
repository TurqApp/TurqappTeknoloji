part of 'deneme_sinavi_yap_controller.dart';

abstract class _DenemeSinaviYapControllerLifecycleBase
    extends _DenemeSinaviYapControllerBase {
  _DenemeSinaviYapControllerLifecycleBase({
    required super.model,
    required super.sinaviBitir,
    required super.showGecersizAlert,
    required super.uyariAtla,
  });

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinaviYapControllerInit(this as DenemeSinaviYapController);
  }

  @override
  void onClose() {
    _handleDenemeSinaviYapControllerClose(this as DenemeSinaviYapController);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _handleDenemeSinaviYapControllerLifecycleChange(
      this as DenemeSinaviYapController,
      state,
    );
  }
}
