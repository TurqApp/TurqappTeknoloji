part of 'create_chat_controller.dart';

class CreateChatController extends GetxController {
  final _state = _CreateChatControllerState();

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
