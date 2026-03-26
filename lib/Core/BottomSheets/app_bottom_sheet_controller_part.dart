part of 'app_bottom_sheet.dart';

class AppBottomSheetController extends GetxController {
  static AppBottomSheetController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      ensureAppBottomSheetController(
        tag: tag,
        permanent: permanent,
      );

  static AppBottomSheetController? maybeFind({String? tag}) =>
      maybeFindAppBottomSheetController(tag: tag);

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
