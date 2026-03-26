part of 'search_tests_controller.dart';

SearchTestsController ensureSearchTestsController({
  String? tag,
  bool permanent = false,
}) =>
    _ensureSearchTestsController(
      tag: tag,
      permanent: permanent,
    );

SearchTestsController? maybeFindSearchTestsController({String? tag}) =>
    _maybeFindSearchTestsController(tag: tag);

extension SearchTestsControllerFacadePart on SearchTestsController {
  void filterSearchResults(String query) =>
      _filterSearchTestsResults(this, query);

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
