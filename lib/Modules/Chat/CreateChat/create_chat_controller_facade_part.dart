part of 'create_chat_controller.dart';

CreateChatController ensureCreateChatController({bool permanent = false}) =>
    maybeFindCreateChatController() ??
    Get.put(CreateChatController(), permanent: permanent);

CreateChatController? maybeFindCreateChatController() =>
    Get.isRegistered<CreateChatController>()
        ? Get.find<CreateChatController>()
        : null;
