import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ProfileContactController extends GetxController {
  var isEmailVisible = false.obs;
  var isCallVisible = false.obs;
  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();
  StreamSubscription<Map<String, dynamic>?>? _userSub;

  @override
  void onInit() {
    super.onInit();
    _bindVisibility();
  }

  void _bindVisibility() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userSub?.cancel();
    _userSub = _userRepository.watchUserRaw(uid).listen((data) {
      if (data == null) return;
      final preferences = (data["preferences"] is Map)
          ? Map<String, dynamic>.from(data["preferences"] as Map)
          : const <String, dynamic>{};
      isEmailVisible.value =
          (data["mailIzin"] ?? preferences["mailIzin"] ?? false) == true;
      isCallVisible.value =
          (data["aramaIzin"] ?? preferences["aramaIzin"] ?? false) == true;
    });
  }

  Future<void> toggleEmailVisibility() async {
    final next = !isEmailVisible.value;
    isEmailVisible.value = next;
    await userService.updateFields({
      "mailIzin": next,
      "preferences.mailIzin": next,
    });
  }

  Future<void> toggleCallVisibility() async {
    final next = !isCallVisible.value;
    isCallVisible.value = next;
    await userService.updateFields({
      "aramaIzin": next,
      "preferences.aramaIzin": next,
    });
  }

  @override
  void onClose() {
    _userSub?.cancel();
    super.onClose();
  }
}
