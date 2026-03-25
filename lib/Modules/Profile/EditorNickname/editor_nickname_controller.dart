import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'editor_nickname_controller_data_part.dart';
part 'editor_nickname_controller_actions_part.dart';

class EditorNicknameController extends GetxController {
  static EditorNicknameController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      EditorNicknameController(),
      permanent: permanent,
    );
  }

  static EditorNicknameController? maybeFind() {
    final isRegistered = Get.isRegistered<EditorNicknameController>();
    if (!isRegistered) return null;
    return Get.find<EditorNicknameController>();
  }

  final TextEditingController nicknameController = TextEditingController();

  final uid = CurrentUserService.instance.effectiveUserId;
  static const Duration _graceWindow = Duration(hours: 1);
  static const Duration _changeCooldown = Duration(days: 15);

  // Live kontrol durumu
  final RxBool isChecking = false.obs;
  final RxnBool isAvailable = RxnBool();
  final RxString statusText = ''.obs;
  final RxBool isCooldownActive = false.obs;
  final RxString cooldownText = ''.obs;
  String _originalNickname = '';
  final RxBool hasUserTyped = false.obs;
  Timer? _debounce;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }

  String get currentNormalized =>
      normalizeEditableNickname(nicknameController.text);

  bool get canSave {
    final name = currentNormalized;
    final available = isAvailable.value == true;
    final longEnough = name.length >= 8;
    final changed = name != _originalNickname;
    final userHasInteracted = hasUserTyped.value || changed;

    // Eğer kullanıcı bir değişiklik yapmışsa ve kullanıcı adı uygunsa kaydet butonunu aktifleştir
    return available &&
        longEnough &&
        userHasInteracted &&
        !isChecking.value &&
        !isCooldownActive.value;
  }

  Future<void> setData() => _setDataImpl();
}
