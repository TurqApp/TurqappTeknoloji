part of 'family_info_controller.dart';

class FamilyInfoController extends GetxController {
  static FamilyInfoController ensure({
    required String tag,
    bool permanent = false,
  }) =>
      _ensureFamilyInfoController(tag: tag, permanent: permanent);

  static FamilyInfoController? maybeFind({required String tag}) =>
      _maybeFindFamilyInfoController(tag: tag);

  static const String _selectValue = "Seçiniz";
  static const String _selectHomeOwnership = "Seçim Yap";
  static const String _selectJob = "Meslek Seç";
  static const String _yesValue = "Evet";
  static const String _noValue = "Hayır";
  static const String _ownedHome = "Kendinize Ait Ev";
  static const String _relativeHome = "Yakınınıza Ait Ev";
  static const String _lodgingHome = "Lojman";
  static const String _rentHome = "Kira";
  final _state = _FamilyInfoControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleFamilyInfoControllerInit(this);
  }
}
