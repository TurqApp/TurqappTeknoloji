part of 'type_writer_controller.dart';

TypewriterController ensureTypewriterController({
  required String fullText,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindTypewriterController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TypewriterController(fullText),
    tag: tag,
    permanent: permanent,
  );
}

TypewriterController? maybeFindTypewriterController({String? tag}) {
  final isRegistered = Get.isRegistered<TypewriterController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TypewriterController>(tag: tag);
}
