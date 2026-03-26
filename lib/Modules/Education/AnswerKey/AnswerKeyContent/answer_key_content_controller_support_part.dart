part of 'answer_key_content_controller.dart';

extension AnswerKeyContentControllerSupportPart on AnswerKeyContentController {
  bool get isOwner => isCurrentUserId(model.userID);

  void syncModel(BookletModel nextModel) {
    model = nextModel;
  }
}
