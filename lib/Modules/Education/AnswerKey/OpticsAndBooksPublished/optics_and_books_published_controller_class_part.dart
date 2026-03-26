part of 'optics_and_books_published_controller.dart';

class OpticsAndBooksPublishedController extends GetxController {
  static OpticsAndBooksPublishedController ensure({
    bool permanent = false,
  }) =>
      _ensureOpticsAndBooksPublishedController(permanent: permanent);

  static OpticsAndBooksPublishedController? maybeFind() =>
      _maybeFindOpticsAndBooksPublishedController();

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _OpticsAndBooksPublishedControllerState();

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
