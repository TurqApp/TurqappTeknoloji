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

extension DenemeSinaviYapControllerShellPart on DenemeSinaviYapController {
  _DenemeSinaviYapControllerState get _state => _shellState.state;
  _DenemeSinaviYapControllerConfig get _config => _shellState.config;
}
