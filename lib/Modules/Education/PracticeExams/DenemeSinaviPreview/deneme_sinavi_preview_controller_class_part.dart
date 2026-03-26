part of 'deneme_sinavi_preview_controller.dart';

class DenemeSinaviPreviewController extends GetxController {
  static DenemeSinaviPreviewController ensure({
    required String tag,
    required SinavModel model,
    bool permanent = false,
  }) =>
      _ensureDenemeSinaviPreviewController(
        tag: tag,
        model: model,
        permanent: permanent,
      );

  static DenemeSinaviPreviewController? maybeFind({required String tag}) =>
      _maybeFindDenemeSinaviPreviewController(tag: tag);

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  final int fifteenMinutes = 15 * 60 * 1000;
  final _state = _DenemeSinaviPreviewControllerState();
  final SinavModel model;
  String get _currentUserId => _currentPracticeExamPreviewUserId();

  DenemeSinaviPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinaviPreviewInit(this);
  }

  Future<void> fetchUserData() => _fetchDenemePreviewUserData(this);

  Future<void> getGecersizlikDurumu() => _getDenemePreviewInvalidState(this);

  Future<void> sinaviBitirAlert() => _sinaviBitirAlertImpl();

  void showGecersizAlert() => _showGecersizAlertImpl();

  Future<void> addBasvuru() => _addBasvuruImpl();

  Future<void> basvuruKontrol() => _checkDenemePreviewApplication(this);

  Future<void> refreshData() => _refreshDenemePreviewData(this);

  Future<void> syncSavedState() => _syncDenemePreviewSavedState(this);

  Future<void> toggleSaved() => _toggleSavedImpl();
}
