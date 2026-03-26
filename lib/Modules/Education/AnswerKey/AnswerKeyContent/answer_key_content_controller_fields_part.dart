part of 'answer_key_content_controller.dart';

class _AnswerKeyContentControllerState {
  final isBookmarked = false.obs;
  final secim = ''.obs;
  final userSubcollectionRepository = UserSubcollectionRepository.ensure();
}

extension AnswerKeyContentControllerFieldsPart on AnswerKeyContentController {
  RxBool get isBookmarked => _state.isBookmarked;
  RxString get secim => _state.secim;
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
}
