part of 'optics_and_books_published_controller.dart';

class OpticsAndBooksPublishedController extends GetxController {
  static OpticsAndBooksPublishedController ensure({
    bool permanent = false,
  }) =>
      _ensureOpticsAndBooksPublishedController(permanent: permanent);

  static OpticsAndBooksPublishedController? maybeFind() =>
      _maybeFindOpticsAndBooksPublishedController();

  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <BookletModel>[].obs;
  final optikler = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final isLoading = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  int _lastOpenRefreshAt = 0;

  @override
  void onInit() {
    super.onInit();
    _handleOpticsAndBooksPublishedInit(this);
  }

  void setSelection(int value) => _setOpticsAndBooksSelection(this, value);

  void refreshOnOpen() => _refreshOpticsAndBooksOnOpen(this);

  Future<void> _bootstrapData() => _bootstrapOpticsAndBooksData(this);

  Future<void> loadData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadOpticsAndBooksData(
        this,
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> getData({bool forceRefresh = false}) => _getPublishedBooksData(
        this,
        forceRefresh: forceRefresh,
      );

  Future<void> getOptikler({bool forceRefresh = false}) =>
      _getPublishedOpticalForms(
        this,
        forceRefresh: forceRefresh,
      );
}
