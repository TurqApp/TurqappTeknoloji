part of 'list_bottom_sheet.dart';

class _ListBottomSheetControllerState {
  final list = <dynamic>[].obs;
  final selectedItems = <String>[].obs;
  final startSelection = ''.obs;
  final searchQuery = ''.obs;
}

extension ListBottomSheetControllerFieldsPart on ListBottomSheetController {
  RxList<dynamic> get list => _state.list;
  RxList<String> get selectedItems => _state.selectedItems;
  RxString get startSelection => _state.startSelection;
  RxString get searchQuery => _state.searchQuery;
}
