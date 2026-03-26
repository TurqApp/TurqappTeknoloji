part of 'create_chat_content_controller.dart';

class CreateChatContentController extends GetxController {
  static CreateChatContentController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateChatContentController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateChatContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<CreateChatContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateChatContentController>(tag: tag);
  }

  final _state = _CreateChatContentControllerState();
  String userID;

  CreateChatContentController({required this.userID});

  @override
  void onInit() {
    super.onInit();
    _handleCreateChatContentInit(this);
  }
}
