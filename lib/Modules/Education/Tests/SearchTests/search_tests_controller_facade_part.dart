part of 'search_tests_controller.dart';

SearchTestsController _ensureSearchTestsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindSearchTestsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SearchTestsController(),
    tag: tag,
    permanent: permanent,
  );
}

SearchTestsController? _maybeFindSearchTestsController({String? tag}) {
  final isRegistered = Get.isRegistered<SearchTestsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SearchTestsController>(tag: tag);
}

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
