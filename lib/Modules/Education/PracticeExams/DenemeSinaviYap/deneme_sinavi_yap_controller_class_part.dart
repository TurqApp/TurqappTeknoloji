part of 'deneme_sinavi_yap_controller.dart';

class DenemeSinaviYapController extends _DenemeSinaviYapControllerBase {
  DenemeSinaviYapController({
    required super.model,
    required super.sinaviBitir,
    required super.showGecersizAlert,
    required super.uyariAtla,
  }) : super();

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinaviYapControllerInit(this);
  }

  @override
  void onClose() {
    _handleDenemeSinaviYapControllerClose(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _handleDenemeSinaviYapControllerLifecycleChange(this, state);
  }
}
