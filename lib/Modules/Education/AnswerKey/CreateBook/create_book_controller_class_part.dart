part of 'create_book_controller.dart';

class CreateBookController extends GetxController {
  static CreateBookController ensure(
    Function? onBack, {
    BookletModel? existingBook,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateBookController(onBack, existingBook: existingBook),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateBookController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateBookController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateBookController>(tag: tag);
  }

  final _CreateBookControllerState _state;

  CreateBookController(
    Function? onBack, {
    BookletModel? existingBook,
  }) : _state = _CreateBookControllerState(
          onBack: onBack,
          existingBook: existingBook,
        );

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _disposeCreateBookController();
    super.onClose();
  }
}
