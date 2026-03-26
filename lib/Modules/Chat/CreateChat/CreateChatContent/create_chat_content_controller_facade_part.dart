part of 'create_chat_content_controller.dart';

class CreateChatContentController extends GetxController {
  final _state = _CreateChatContentControllerState();
  String userID;

  CreateChatContentController({required this.userID});

  @override
  void onInit() {
    super.onInit();
    _handleCreateChatContentInit(this);
  }
}

class _CreateChatContentControllerState {
  final RxString nickname = ''.obs;
  final RxString fullName = ''.obs;
  final RxString avatarUrl = ''.obs;
}

CreateChatContentController ensureCreateChatContentController({
  required String userID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateChatContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateChatContentController(userID: userID),
    tag: tag,
    permanent: permanent,
  );
}

CreateChatContentController? maybeFindCreateChatContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<CreateChatContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateChatContentController>(tag: tag);
}
