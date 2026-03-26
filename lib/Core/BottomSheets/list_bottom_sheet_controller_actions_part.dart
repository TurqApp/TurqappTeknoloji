part of 'list_bottom_sheet.dart';

ListBottomSheetController ensureListBottomSheetController({
  String? tag,
  bool permanent = false,
}) =>
    _ensureListBottomSheetController(tag: tag, permanent: permanent);

ListBottomSheetController? maybeFindListBottomSheetController({String? tag}) =>
    _maybeFindListBottomSheetController(tag: tag);

ListBottomSheetController _ensureListBottomSheetController({
  String? tag,
  bool permanent = false,
}) =>
    _maybeFindListBottomSheetController(tag: tag) ??
    Get.put(
      ListBottomSheetController(),
      tag: tag,
      permanent: permanent,
    );

ListBottomSheetController? _maybeFindListBottomSheetController({
  String? tag,
}) =>
    Get.isRegistered<ListBottomSheetController>(tag: tag)
        ? Get.find<ListBottomSheetController>(tag: tag)
        : null;

extension ListBottomSheetControllerActionsPart on ListBottomSheetController {
  void initSingleSelection(List<dynamic> items, dynamic initialSelection) =>
      _initListBottomSheetSingleSelection(
        this,
        items: items,
        initialSelection: initialSelection,
      );

  void initMultiSelection(List<String> initialSelections) =>
      _initListBottomSheetMultiSelection(this, initialSelections);

  void selectItem(dynamic item, Function(dynamic) onBackData) =>
      _selectListBottomSheetItem(this, item, onBackData);

  void toggleSelection(String item) =>
      _toggleListBottomSheetSelection(this, item);

  void confirmMultiSelection(Function(List<String>) onBackData) =>
      _confirmListBottomSheetMultiSelection(this, onBackData);

  void filterList(
    String query,
    List<dynamic> originalList, {
    String Function(dynamic item)? searchTextBuilder,
  }) =>
      _filterListBottomSheetItems(
        this,
        query: query,
        originalList: originalList,
        searchTextBuilder: searchTextBuilder,
      );
}

void _initListBottomSheetSingleSelection(
  ListBottomSheetController controller, {
  required List<dynamic> items,
  required dynamic initialSelection,
}) {
  controller.list.value = items;
  controller.startSelection.value = initialSelection?.toString() ?? '';
  controller.list.value = items;
}

void _initListBottomSheetMultiSelection(
  ListBottomSheetController controller,
  List<String> initialSelections,
) {
  controller.selectedItems.value = initialSelections;
}

void _selectListBottomSheetItem(
  ListBottomSheetController controller,
  dynamic item,
  Function(dynamic) onBackData,
) {
  controller.startSelection.value = item.toString();
  onBackData(item);
  Get.back();
}

void _toggleListBottomSheetSelection(
  ListBottomSheetController controller,
  String item,
) {
  if (controller.selectedItems.contains(item)) {
    controller.selectedItems.remove(item);
  } else {
    controller.selectedItems.add(item);
  }
}

void _confirmListBottomSheetMultiSelection(
  ListBottomSheetController controller,
  Function(List<String>) onBackData,
) {
  onBackData(controller.selectedItems);
  Get.back();
}

void _filterListBottomSheetItems(
  ListBottomSheetController controller, {
  required String query,
  required List<dynamic> originalList,
  String Function(dynamic item)? searchTextBuilder,
}) {
  controller.searchQuery.value = query;
  if (query.isEmpty) {
    controller.list.value = originalList;
    return;
  }
  final normalizedQuery = normalizeSearchText(query);
  controller.list.value = originalList
      .where(
        (item) => normalizeSearchText(
          searchTextBuilder?.call(item) ?? item.toString(),
        ).contains(normalizedQuery),
      )
      .toList();
}
