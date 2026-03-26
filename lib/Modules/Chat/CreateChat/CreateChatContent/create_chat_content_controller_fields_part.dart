part of 'create_chat_content_controller.dart';

class _CreateChatContentControllerState {
  final RxString nickname = ''.obs;
  final RxString fullName = ''.obs;
  final RxString avatarUrl = ''.obs;
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
}

extension CreateChatContentControllerFieldsPart on CreateChatContentController {
  RxString get nickname => _state.nickname;
  RxString get fullName => _state.fullName;
  RxString get avatarUrl => _state.avatarUrl;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
}
