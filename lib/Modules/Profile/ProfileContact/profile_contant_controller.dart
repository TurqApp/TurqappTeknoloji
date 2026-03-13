import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ProfileContactController extends GetxController {
  var isEmailVisible = true.obs;
  var isCallVisible = true.obs;
  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await _userRepository.getUserRaw(uid);
    if (data == null) return;
    isEmailVisible.value = data["mailIzin"] == true;
    isCallVisible.value = data["aramaIzin"] == true;
  }

  void toggleEmailVisibility() {
    isEmailVisible.value = !isEmailVisible.value;
    userService.updateFields({"mailIzin": isEmailVisible.value});
  }

  void toggleCallVisibility() {
    isCallVisible.value = !isCallVisible.value;
    userService.updateFields({"aramaIzin": isCallVisible.value});
  }
}
