part of 'deneme_sinavi_yap_controller.dart';

DenemeSinaviYapController ensureDenemeSinaviYapController({
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

DenemeSinaviYapController? maybeFindDenemeSinaviYapController({
  required String tag,
}) =>
    _maybeFindDenemeSinaviYapController(tag: tag);

extension DenemeSinaviYapControllerFacadePart on DenemeSinaviYapController {
  Future<void> fetchUserData() =>
      _DenemeSinaviYapControllerRuntimePart(this).fetchUserData();

  Future<void> getSorular() =>
      _DenemeSinaviYapControllerRuntimePart(this).getSorular();

  void checkInternetConnection() =>
      _DenemeSinaviYapControllerRuntimePart(this).checkInternetConnection();

  void sinaviGecersizSay() =>
      _DenemeSinaviYapControllerRuntimePart(this).sinaviGecersizSay();

  Future<void> setData() =>
      _DenemeSinaviYapControllerRuntimePart(this).setData();

  Future<void> refreshData() =>
      _DenemeSinaviYapControllerRuntimePart(this).refreshData();
}
