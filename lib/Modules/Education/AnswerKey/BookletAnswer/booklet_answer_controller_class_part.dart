part of 'booklet_answer_controller.dart';

class BookletAnswerController extends GetxController {
  final _BookletAnswerControllerState _state;

  BookletAnswerController(AnswerKeySubModel model, BookletModel anaModel)
      : _state = _BookletAnswerControllerState(
          model: model,
          anaModel: anaModel,
        );

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}
