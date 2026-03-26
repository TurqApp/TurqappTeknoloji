part of 'search_tests_controller.dart';

class SearchTestsController extends GetxController {
  static SearchTestsController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureSearchTestsController(
        tag: tag,
        permanent: permanent,
      );

  static SearchTestsController? maybeFind({String? tag}) =>
      _maybeFindSearchTestsController(tag: tag);

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SearchTestsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSearchTestsControllerInit(this);
  }

  void filterSearchResults(String query) =>
      _filterSearchTestsResults(this, query);

  @override
  void onClose() {
    _handleSearchTestsControllerClose(this);
    super.onClose();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getSearchTestsData(
        this,
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
