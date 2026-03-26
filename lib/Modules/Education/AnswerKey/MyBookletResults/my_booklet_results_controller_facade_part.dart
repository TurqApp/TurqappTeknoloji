part of 'my_booklet_results_controller.dart';

extension MyBookletResultsControllerFacadePart on MyBookletResultsController {
  void setSelection(int value) {
    selection.value = value;
  }

  Future<void> _bootstrapResults() =>
      MyBookletResultsControllerRuntimePart(this).bootstrapResults();

  Future<void> fetchBookletResults({bool forceRefresh = false}) =>
      MyBookletResultsControllerRuntimePart(this)
          .fetchBookletResults(forceRefresh: forceRefresh);

  Future<void> fetchOptikSonuclari({bool forceRefresh = false}) =>
      MyBookletResultsControllerRuntimePart(this)
          .fetchOptikSonuclari(forceRefresh: forceRefresh);

  Future<void> refreshData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      MyBookletResultsControllerRuntimePart(this).refreshData(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  void _assignBookletResults(List<UserSubcollectionEntry> snapshot) =>
      MyBookletResultsControllerRuntimePart(this)
          .assignBookletResults(snapshot);
}
