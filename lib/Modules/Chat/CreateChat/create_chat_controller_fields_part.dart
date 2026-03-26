part of 'create_chat_controller.dart';

class _CreateChatControllerState {
  final TextEditingController search = TextEditingController();
  final RxString selected = ''.obs;
  final RxString query = ''.obs;
}

extension CreateChatControllerFieldsPart on CreateChatController {
  TextEditingController get search => _state.search;
  RxString get selected => _state.selected;
  RxString get query => _state.query;
}
