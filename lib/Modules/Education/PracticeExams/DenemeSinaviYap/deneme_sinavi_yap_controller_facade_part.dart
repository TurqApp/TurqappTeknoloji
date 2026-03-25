part of 'deneme_sinavi_yap_controller.dart';

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
