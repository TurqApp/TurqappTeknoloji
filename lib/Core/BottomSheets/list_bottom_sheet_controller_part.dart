part of 'list_bottom_sheet.dart';

class ListBottomSheetController extends GetxController {
  static ListBottomSheetController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ListBottomSheetController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static ListBottomSheetController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ListBottomSheetController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ListBottomSheetController>(tag: tag);
  }

  final list = <dynamic>[].obs;
  final selectedItems = <String>[].obs;
  final startSelection = "".obs;
  final searchQuery = "".obs;

  void initSingleSelection(List<dynamic> items, dynamic initialSelection) {
    list.value = items;
    startSelection.value = initialSelection?.toString() ?? "";
    list.value = items;
  }

  void initMultiSelection(List<String> initialSelections) {
    selectedItems.value = initialSelections;
  }

  void selectItem(dynamic item, Function(dynamic) onBackData) {
    startSelection.value = item.toString();
    onBackData(item);
    Get.back();
  }

  void toggleSelection(String item) {
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
  }

  void confirmMultiSelection(Function(List<String>) onBackData) {
    onBackData(selectedItems);
    Get.back();
  }

  void filterList(
    String query,
    List<dynamic> originalList, {
    String Function(dynamic item)? searchTextBuilder,
  }) {
    searchQuery.value = query;
    if (query.isEmpty) {
      list.value = originalList;
    } else {
      final normalizedQuery = normalizeSearchText(query);
      list.value = originalList
          .where(
            (item) => normalizeSearchText(
              searchTextBuilder?.call(item) ?? item.toString(),
            ).contains(normalizedQuery),
          )
          .toList();
    }
  }
}
