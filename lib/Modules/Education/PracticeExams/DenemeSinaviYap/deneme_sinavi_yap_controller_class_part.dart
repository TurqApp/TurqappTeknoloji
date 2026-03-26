part of 'deneme_sinavi_yap_controller.dart';

class DenemeSinaviYapController extends GetxController
    with WidgetsBindingObserver {
  static DenemeSinaviYapController ensure({
    required String tag,
    required SinavModel model,
    required Function sinaviBitir,
    required Function showGecersizAlert,
    required bool uyariAtla,
    bool permanent = false,
  }) =>
      _ensureDenemeSinaviYapController(
        tag: tag,
        model: model,
        sinaviBitir: sinaviBitir,
        showGecersizAlert: showGecersizAlert,
        uyariAtla: uyariAtla,
        permanent: permanent,
      );

  static DenemeSinaviYapController? maybeFind({required String tag}) =>
      _maybeFindDenemeSinaviYapController(tag: tag);

  final _DenemeSinaviYapControllerShellState _shellState;

  DenemeSinaviYapController({
    required SinavModel model,
    required Function sinaviBitir,
    required Function showGecersizAlert,
    required bool uyariAtla,
  }) : _shellState = _buildDenemeSinaviYapControllerShellState(
          model: model,
          sinaviBitir: sinaviBitir,
          showGecersizAlert: showGecersizAlert,
          uyariAtla: uyariAtla,
        );

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
