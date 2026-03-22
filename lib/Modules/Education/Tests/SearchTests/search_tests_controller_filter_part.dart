part of 'search_tests_controller.dart';

extension SearchTestsControllerFilterPart on SearchTestsController {
  void filterSearchResults(String query) {
    final normalizedQuery = normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where(
          (test) =>
              normalizeSearchText(test.aciklama).contains(normalizedQuery) ||
              normalizeSearchText(test.testTuru).contains(normalizedQuery) ||
              test.dersler.any(
                (ders) => normalizeSearchText(ders).contains(normalizedQuery),
              ),
        ),
      );
    }
  }
}
