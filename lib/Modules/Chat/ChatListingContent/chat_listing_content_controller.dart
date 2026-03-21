import 'package:get/get.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';

class ChatListingContentController extends GetxController {
  static ChatListingContentController ensure({
    required String userID,
    required ChatListingModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ChatListingContentController(userID: userID, model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static ChatListingContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<ChatListingContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ChatListingContentController>(tag: tag);
  }

  String userID;
  ChatListingModel model;
  var notReadCounter = 0.obs;
  RxList<MessageModel> lastMessage = <MessageModel>[].obs;
  Worker? _listWorker;

  ChatListingContentController({
    required this.userID,
    required this.model,
  });

  @override
  void onInit() {
    super.onInit();
    notReadCounter.value = model.unreadCount;
    _bindListingState();
    if (model.lastMessage.isNotEmpty) {
      lastMessage.assignAll([
        MessageModel(
          docID: "preview_${model.chatID}",
          rawDocID: "preview_${model.chatID}",
          source: "preview",
          timeStamp: num.tryParse(model.timeStamp) ?? 0,
          userID: model.userID,
          lat: 0,
          long: 0,
          postType: "",
          postID: "",
          imgs: const [],
          video: "",
          isRead: model.unreadCount <= 0,
          kullanicilar: const [],
          metin: model.lastMessage,
          sesliMesaj: "",
          kisiAdSoyad: "",
          kisiTelefon: "",
          begeniler: const [],
          isEdited: false,
          isUnsent: false,
          isForwarded: false,
          replyMessageId: "",
          replySenderId: "",
          replyText: "",
          replyType: "",
          reactions: const {},
        )
      ]);
    }
  }

  void _bindListingState() {
    final listing = ChatListingController.maybeFind();
    if (listing == null) return;
    _listWorker = ever<List<ChatListingModel>>(listing.list, (_) {
      final latest =
          listing.list.firstWhereOrNull((e) => e.chatID == model.chatID);
      if (latest == null) return;
      model = latest;
      notReadCounter.value = latest.unreadCount;
      if (latest.lastMessage.trim().isNotEmpty) {
        lastMessage.assignAll([
          MessageModel(
            docID: "preview_${latest.chatID}",
            rawDocID: "preview_${latest.chatID}",
            source: "preview",
            timeStamp: num.tryParse(latest.timeStamp) ?? 0,
            userID: latest.userID,
            lat: 0,
            long: 0,
            postType: "",
            postID: "",
            imgs: const [],
            video: "",
            isRead: latest.unreadCount <= 0,
            kullanicilar: const [],
            metin: latest.lastMessage,
            sesliMesaj: "",
            kisiAdSoyad: "",
            kisiTelefon: "",
            begeniler: const [],
            isEdited: false,
            isUnsent: false,
            isForwarded: false,
            replyMessageId: "",
            replySenderId: "",
            replyText: "",
            replyType: "",
            reactions: const {},
          ),
        ]);
      }
    });
  }

  @override
  void onClose() {
    _listWorker?.dispose();
    super.onClose();
  }
}
