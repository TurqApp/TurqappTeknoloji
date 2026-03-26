part of 'deneme_sinavi_yap_controller.dart';

abstract class _DenemeSinaviYapControllerBase extends GetxController
    with WidgetsBindingObserver {
  _DenemeSinaviYapControllerBase({
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

  final _DenemeSinaviYapControllerShellState _shellState;
}
