part of 'answer_key_content_controller.dart';

class _AnswerKeyContentControllerState {
  _AnswerKeyContentControllerState({
    required this.model,
    required this.onUpdate,
  });

  BookletModel model;
  final Function(bool) onUpdate;
  final isBookmarked = false.obs;
  final secim = ''.obs;
  final userSubcollectionRepository = UserSubcollectionRepository.ensure();
}

extension AnswerKeyContentControllerFieldsPart on AnswerKeyContentController {
  BookletModel get model => _state.model;
  set model(BookletModel value) => _state.model = value;
  Function(bool) get onUpdate => _state.onUpdate;
  RxBool get isBookmarked => _state.isBookmarked;
  RxString get secim => _state.secim;
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
}
