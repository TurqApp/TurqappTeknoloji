part of 'create_chat_controller.dart';

class CreateChatController extends GetxController {
  static CreateChatController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CreateChatController(), permanent: permanent);
  }

  static CreateChatController? maybeFind() {
    final isRegistered = Get.isRegistered<CreateChatController>();
    if (!isRegistered) return null;
    return Get.find<CreateChatController>();
  }

  TextEditingController search = TextEditingController();
  var selected = "".obs;
  final RxString query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debounce<String>(query, (val) async {
      final q = normalizeSearchText(val);
      final followers = maybeFindFollowingFollowersController();
      if (followers == null) return;
      followers.searchTakipEdilenController.text = q;
      if (q.length >= 2) {
        await followers.searchTakipEdilenler();
      } else {
        await followers.getFollowing(initial: true);
      }
    }, time: const Duration(milliseconds: 300));
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
