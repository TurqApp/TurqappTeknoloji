import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';

class CreateChatController extends GetxController {
  TextEditingController search = TextEditingController();
  var selected = "".obs;
  final RxString query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Debounce arama: 300ms sonra tetikle
    debounce<String>(query, (val) async {
      final q = normalizeSearchText(val);
      if (!Get.isRegistered<FollowingFollowersController>()) return;
      final followers = Get.find<FollowingFollowersController>();
      followers.searchTakipEdilenController.text = q;
      if (q.length >= 2) {
        await followers.searchTakipEdilenler();
      } else {
        // kısa sorguda başlangıç listesini geri yükle
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
