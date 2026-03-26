part of 'optics_and_books_published_controller_library.dart';

OpticsAndBooksPublishedController ensureOpticsAndBooksPublishedController({
  bool permanent = false,
}) =>
    _ensureOpticsAndBooksPublishedController(permanent: permanent);

OpticsAndBooksPublishedController?
    maybeFindOpticsAndBooksPublishedController() =>
        _maybeFindOpticsAndBooksPublishedController();

OpticsAndBooksPublishedController _ensureOpticsAndBooksPublishedController({
  bool permanent = false,
}) {
  final existing = _maybeFindOpticsAndBooksPublishedController();
  if (existing != null) return existing;
  return Get.put(OpticsAndBooksPublishedController(), permanent: permanent);
}

OpticsAndBooksPublishedController?
    _maybeFindOpticsAndBooksPublishedController() {
  final isRegistered = Get.isRegistered<OpticsAndBooksPublishedController>();
  if (!isRegistered) return null;
  return Get.find<OpticsAndBooksPublishedController>();
}

void _handleOpticsAndBooksPublishedInit(
  OpticsAndBooksPublishedController controller,
) {
  unawaited(_bootstrapOpticsAndBooksData(controller));
}

void _setOpticsAndBooksSelection(
  OpticsAndBooksPublishedController controller,
  int value,
) {
  controller.selection.value = value;
}

void _refreshOpticsAndBooksOnOpen(
  OpticsAndBooksPublishedController controller,
) {
  final now = DateTime.now().millisecondsSinceEpoch;
  if (controller.isLoading.value) return;
  if (now - controller._lastOpenRefreshAt < 800) return;
  controller._lastOpenRefreshAt = now;
  unawaited(_loadOpticsAndBooksData(controller, forceRefresh: true));
}

Future<void> _bootstrapOpticsAndBooksData(
  OpticsAndBooksPublishedController controller,
) =>
    _OpticsAndBooksPublishedControllerRuntimeX(controller)._bootstrapData();

Future<void> _loadOpticsAndBooksData(
  OpticsAndBooksPublishedController controller, {
  bool silent = false,
  bool forceRefresh = false,
}) =>
    _OpticsAndBooksPublishedControllerRuntimeX(controller).loadData(
      silent: silent,
      forceRefresh: forceRefresh,
    );

Future<void> _getPublishedBooksData(
  OpticsAndBooksPublishedController controller, {
  bool forceRefresh = false,
}) =>
    _OpticsAndBooksPublishedControllerRuntimeX(controller).getData(
      forceRefresh: forceRefresh,
    );

Future<void> _getPublishedOpticalForms(
  OpticsAndBooksPublishedController controller, {
  bool forceRefresh = false,
}) =>
    _OpticsAndBooksPublishedControllerRuntimeX(controller).getOptikler(
      forceRefresh: forceRefresh,
    );

extension OpticsAndBooksPublishedControllerFacadePart
    on OpticsAndBooksPublishedController {
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
