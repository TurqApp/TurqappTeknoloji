part of 'app_bottom_sheet.dart';

AppBottomSheetController ensureAppBottomSheetController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindAppBottomSheetController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    AppBottomSheetController(),
    tag: tag,
    permanent: permanent,
  );
}

AppBottomSheetController? maybeFindAppBottomSheetController({String? tag}) {
  final isRegistered = Get.isRegistered<AppBottomSheetController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<AppBottomSheetController>(tag: tag);
}
