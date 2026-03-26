part of 'search_deneme_controller.dart';

SearchDenemeController ensureSearchDenemeController({
  bool permanent = false,
}) {
  final existing = maybeFindSearchDenemeController();
  if (existing != null) return existing;
  return Get.put(SearchDenemeController(), permanent: permanent);
}

SearchDenemeController? maybeFindSearchDenemeController() {
  final isRegistered = Get.isRegistered<SearchDenemeController>();
  if (!isRegistered) return null;
  return Get.find<SearchDenemeController>();
}

extension SearchDenemeControllerFacadePart on SearchDenemeController {
  Future<void> getData() => _performSearchDenemeDataLoad();

  Future<void> filterSearchResults(String query) =>
      _performFilterSearchResults(query);

  void resetSearch() => _resetSearchState();
}
