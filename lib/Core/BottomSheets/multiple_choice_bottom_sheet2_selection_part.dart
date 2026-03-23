part of 'multiple_choice_bottom_sheet2.dart';

extension MultiSelectBottomSheet2SelectionPart on MultiSelectBottomSheet2 {
  bool isAllUniversitiesValue(String value) {
    final normalized = value.trim();
    return const <String>{
      MultiSelectBottomSheet2._allUniversitiesValue,
      MultiSelectBottomSheet2._allUniversitiesKey,
      'All Universities',
      'Alle Universitäten',
      'Toutes les universités',
      'Tutte le università',
      'Все университеты',
    }.contains(normalized);
  }

  bool containsSelectedValue(List<String> values, String item) {
    if (isAllUniversitiesValue(item)) {
      return values.any(isAllUniversitiesValue);
    }
    return values.contains(item);
  }

  List<String> resolveBaseItems() {
    return (relatedItems != null && parentSelection != null)
        ? relatedItems![parentSelection!] ?? items
        : items;
  }

  List<String> filterItems(String query) {
    final baseItems = resolveBaseItems();
    if (query.isEmpty) return baseItems;
    final normalizedQuery = normalizeSearchText(query);
    return baseItems
        .where((item) => normalizeSearchText(item).contains(normalizedQuery))
        .toList();
  }

  void toggleSelection(RxList<String> tempSelectedItems, String item) {
    if (isAllUniversitiesValue(item)) {
      if (containsSelectedValue(tempSelectedItems, item)) {
        tempSelectedItems.clear();
      } else {
        tempSelectedItems.assignAll(
          <String>[MultiSelectBottomSheet2._allUniversitiesValue],
        );
      }
      return;
    }

    tempSelectedItems.removeWhere(isAllUniversitiesValue);
    if (containsSelectedValue(tempSelectedItems, item)) {
      tempSelectedItems.remove(item);
    } else {
      tempSelectedItems.add(item);
    }
  }

  List<String> confirmedSelection(List<String> tempSelectedItems) {
    if (tempSelectedItems.any(isAllUniversitiesValue)) {
      return <String>[MultiSelectBottomSheet2._allUniversitiesValue];
    }
    return List<String>.from(tempSelectedItems);
  }
}
