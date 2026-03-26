part of 'list_bottom_sheet.dart';

class ListBottomSheetController extends GetxController {
  static ListBottomSheetController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      _ensureListBottomSheetController(tag: tag, permanent: permanent);

  static ListBottomSheetController? maybeFind({String? tag}) =>
      _maybeFindListBottomSheetController(tag: tag);

  final _state = _ListBottomSheetControllerState();

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
