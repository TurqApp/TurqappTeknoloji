part of 'interest_controller.dart';

extension InterestsControllerDataPart on InterestsController {
  String _norm(String value) {
    return normalizeSearchText(value).replaceAll(RegExp(r'\s+'), ' ');
  }

  String _canonicalize(String value) {
    final normalized = _norm(value);
    for (final item in interestList) {
      if (_norm(item) == normalized) {
        return item;
      }
    }
    return value.trim();
  }

  bool isSelected(String item) {
    final canonical = _canonicalize(item);
    return selecteds.any((e) => _canonicalize(e) == canonical);
  }

  List<String> filterItems(List<String> allItems) {
    final query = normalizeSearchText(searchText.value);
    if (query.isEmpty) {
      return allItems;
    }
    return allItems
        .where((item) => normalizeSearchText(item).contains(query))
        .toList(growable: false);
  }
}
