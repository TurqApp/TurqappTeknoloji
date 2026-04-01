part of 'view_changer_controller.dart';

ViewChangerController ensureViewChangerController({
  required RxInt selection,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindViewChangerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ViewChangerController(selection: selection),
    tag: tag,
    permanent: permanent,
  );
}

ViewChangerController? maybeFindViewChangerController({String? tag}) {
  final isRegistered = Get.isRegistered<ViewChangerController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ViewChangerController>(tag: tag);
}
