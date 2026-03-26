part of 'optics_and_books_published_controller.dart';

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
  unawaited(controller._bootstrapData());
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
  controller.loadData(forceRefresh: true);
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
