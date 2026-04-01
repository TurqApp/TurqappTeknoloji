part of 'deneme_sinavi_yap_controller.dart';

DenemeSinaviYapController _ensureDenemeSinaviYapController({
  required String tag,
  required SinavModel model,
  required Function sinaviBitir,
  required Function showGecersizAlert,
  required bool uyariAtla,
  bool permanent = false,
}) {
  final existing = _maybeFindDenemeSinaviYapController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    DenemeSinaviYapController(
      model: model,
      sinaviBitir: sinaviBitir,
      showGecersizAlert: showGecersizAlert,
      uyariAtla: uyariAtla,
    ),
    tag: tag,
    permanent: permanent,
  );
}

DenemeSinaviYapController? _maybeFindDenemeSinaviYapController({
  required String tag,
}) =>
    Get.isRegistered<DenemeSinaviYapController>(tag: tag)
        ? Get.find<DenemeSinaviYapController>(tag: tag)
        : null;

class _DenemeSinaviYapControllerShellState {
  final state = _DenemeSinaviYapControllerState();
  late _DenemeSinaviYapControllerConfig config;
}

_DenemeSinaviYapControllerShellState _buildDenemeSinaviYapControllerShellState({
  required SinavModel model,
  required Function sinaviBitir,
  required Function showGecersizAlert,
  required bool uyariAtla,
}) {
  final shellState = _DenemeSinaviYapControllerShellState();
  shellState.config = _DenemeSinaviYapControllerConfig(
    model: model,
    sinaviBitir: sinaviBitir,
    showGecersizAlert: showGecersizAlert,
    uyariAtla: uyariAtla,
  );
  return shellState;
}

void _handleDenemeSinaviYapControllerInit(
  DenemeSinaviYapController controller,
) {
  _DenemeSinaviYapControllerRuntimePart(controller).handleOnInit();
}

void _handleDenemeSinaviYapControllerClose(
  DenemeSinaviYapController controller,
) {
  _DenemeSinaviYapControllerRuntimePart(controller).handleOnClose();
}

void _handleDenemeSinaviYapControllerLifecycleChange(
  DenemeSinaviYapController controller,
  AppLifecycleState state,
) {
  _DenemeSinaviYapControllerRuntimePart(controller)
      .didChangeAppLifecycleState(state);
}
