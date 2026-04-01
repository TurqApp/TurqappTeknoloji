part of 'app_bottom_sheet.dart';

class AppBottomSheetController extends GetxController {
  final list = <dynamic>[].obs;
  final startSelection = ''.obs;

  void initSelection(List<dynamic> items, dynamic initialSelection) {
    list.value = items;
    startSelection.value = initialSelection?.toString() ?? '';
  }

  void selectItem(dynamic item, Function(dynamic) onBackData) {
    startSelection.value = item.toString();
    onBackData(item);
    Get.back();
  }
}
