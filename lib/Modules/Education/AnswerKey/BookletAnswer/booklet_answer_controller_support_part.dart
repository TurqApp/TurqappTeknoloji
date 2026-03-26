part of 'booklet_answer_controller.dart';

class BookletAnswerController extends GetxController {
  final _BookletAnswerControllerState _state;

  BookletAnswerController(AnswerKeySubModel model, BookletModel anaModel)
      : _state =
            _BookletAnswerControllerState(model: model, anaModel: anaModel);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}

BookletAnswerController ensureBookletAnswerController(
  AnswerKeySubModel model,
  BookletModel anaModel, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindBookletAnswerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    BookletAnswerController(model, anaModel),
    tag: tag,
    permanent: permanent,
  );
}

BookletAnswerController? maybeFindBookletAnswerController({String? tag}) {
  final isRegistered = Get.isRegistered<BookletAnswerController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<BookletAnswerController>(tag: tag);
}
