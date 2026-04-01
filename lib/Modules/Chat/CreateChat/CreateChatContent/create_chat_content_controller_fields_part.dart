part of 'create_chat_content_controller.dart';

extension CreateChatContentControllerFieldsPart on CreateChatContentController {
  RxString get nickname => _state.nickname;
  RxString get fullName => _state.fullName;
  RxString get avatarUrl => _state.avatarUrl;
  UserSummaryResolver get _userSummaryResolver => UserSummaryResolver.ensure();
}
