part of 'deneme_sinavlari_controller.dart';

class DenemeSinavlariController extends GetxController {
  static DenemeSinavlariController ensure({
    bool permanent = false,
  }) =>
      _ensureDenemeSinavlariController(permanent: permanent);

  static DenemeSinavlariController? maybeFind() =>
      _maybeFindDenemeSinavlariController();

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_practice_exam_listing_selection';
  final _state = _DenemeSinavlariControllerState();
  static const int _pageSize = ReadBudgetRegistry.practiceExamHomeInitialLimit;

  bool get hasActiveSearch => _hasActivePracticeExamSearch(this);

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinavlariInit(this);
  }

  @override
  void onClose() {
    _handleDenemeSinavlariClose(this);
    super.onClose();
  }
}
