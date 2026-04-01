part of 'create_book_controller.dart';

CreateBookController ensureCreateBookController(
  Function? onBack, {
  BookletModel? existingBook,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateBookController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateBookController(onBack, existingBook: existingBook),
    tag: tag,
    permanent: permanent,
  );
}

CreateBookController? maybeFindCreateBookController({String? tag}) {
  final isRegistered = Get.isRegistered<CreateBookController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateBookController>(tag: tag);
}

extension CreateBookControllerSupportPart on CreateBookController {
  void _disposeCreateBookController() {
    baslikController.dispose();
    yayinEviController.dispose();
    basimTarihiController.dispose();
  }
}
