import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class EditorNicknameController extends GetxController {
  final TextEditingController nicknameController = TextEditingController();

  final uid = FirebaseAuth.instance.currentUser!.uid;
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
  static const Map<String, String> _trMap = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
  };

  @override
  void onInit() {
    super.onInit();
    _seedFromCurrentUser();
    unawaited(fetchAndSetUserData());
    // Metin değişimini dinle ve debounce ile kontrol et
    nicknameController.addListener(_onTextChanged);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    nicknameController.removeListener(_onTextChanged);
    nicknameController.dispose();
    super.onClose();
  }

  void _seedFromCurrentUser() {
    final currentUser = CurrentUserService.instance.currentUser;
    if (currentUser == null) return;
    final nickname = currentUser.nickname.trim();
    if (nickname.isEmpty) return;
    nicknameController.text = nickname;
    _originalNickname = nickname;
  }

  Future<void> fetchAndSetUserData() async {
    final data = await _userRepository.getUserRaw(uid);
    if (data != null) {
      final nickname = data["nickname"] ?? "";
      nicknameController.text = nickname;
      // Orijinal değeri sakla
      _originalNickname = nickname;
      _updateCooldownState(data);
      // İlk yüklemede uygunluk durumunu hesapla
      _triggerDebouncedCheck();
    }
  }

  void _onTextChanged() {
    final currentText = nicknameController.text;
    final norm = _normalize(currentText);

    // Kullanıcının gerçekten yazdığını işaretle
    if (currentText.isNotEmpty && currentText != _originalNickname) {
      hasUserTyped.value = true;
    }

    if (currentText != norm) {
      // Kullanıcı yasak karakter girdi ise anında normalize et
      nicknameController.value = nicknameController.value.copyWith(
        text: norm,
        selection: TextSelection.collapsed(offset: norm.length),
      );
    }
    _triggerDebouncedCheck();
  }

  void _triggerDebouncedCheck() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      await checkAvailability();
    });
  }

  String _normalize(String raw) {
    String normalized = raw.trim().toLowerCase();
    for (final entry in _trMap.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9._]'), '');
    return normalized;
  }

  String get currentNormalized => _normalize(nicknameController.text);

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

  int? _parseMillis(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    return null;
  }

  int? _extractCreatedAt(Map<String, dynamic> data) {
    return _parseMillis(data['createdDate']) ??
        _parseMillis(data['createdDate']) ??
        _parseMillis(data['timeStamp']);
  }

  int? _extractLastChangeAt(Map<String, dynamic> data) {
    return _parseMillis(data['nicknameChangedAt']) ??
        _parseMillis(data['nicknameLastChangedAt']);
  }

  int _extractGraceCount(Map<String, dynamic> data) {
    final raw = data['nicknameGraceChangeCount'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  void _updateCooldownState(Map<String, dynamic> data) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final createdAtMs = _extractCreatedAt(data);
    final lastChangeMs = _extractLastChangeAt(data);

    // Kural:
    // - Son nickname değişiminden sonraki ilk 1 saat: serbest
    // - 1 saatten sonra, 15 gün dolana kadar: kilit
    // - 15 gün dolunca: tekrar serbest
    if (lastChangeMs != null) {
      final elapsed = nowMs - lastChangeMs;
      if (elapsed <= _graceWindow.inMilliseconds) {
        final graceCount = _extractGraceCount(data);
        if (graceCount >= 3) {
          isCooldownActive.value = true;
          cooldownText.value = 'editor_nickname.cooldown_limit'.tr;
          return;
        }
        isCooldownActive.value = false;
        cooldownText.value = '';
        return;
      }
      if (elapsed < _changeCooldown.inMilliseconds) {
        final left =
            Duration(milliseconds: _changeCooldown.inMilliseconds - elapsed);
        final days = left.inDays;
        final hours = left.inHours % 24;
        isCooldownActive.value = true;
        if (days > 0) {
          cooldownText.value = 'editor_nickname.change_after_days'
              .trParams({'days': '$days', 'hours': '$hours'});
        } else {
          cooldownText.value = 'editor_nickname.change_after_hours'
              .trParams({'hours': '${left.inHours}'});
        }
        return;
      }
      isCooldownActive.value = false;
      cooldownText.value = '';
      return;
    }

    // Hesapta henüz nickname değişim kaydı yoksa, ilk 1 saat serbest kalsın.
    final withinSignupGrace = createdAtMs != null &&
        (nowMs - createdAtMs) <= _graceWindow.inMilliseconds;
    if (withinSignupGrace) {
      isCooldownActive.value = false;
      cooldownText.value = '';
      return;
    }

    isCooldownActive.value = false;
    cooldownText.value = '';
  }

  Future<void> checkAvailability() async {
    final name = currentNormalized;
    if (name.isEmpty) {
      isAvailable.value = null;
      statusText.value = '';
      return;
    }
    if (isCooldownActive.value) {
      isAvailable.value = false;
      statusText.value = cooldownText.value;
      return;
    }
    if (name.length < 8) {
      isAvailable.value = false;
      statusText.value = 'editor_nickname.min_length'.tr;
      return;
    }

    // Eğer değişmemişse ama kullanıcı etkileşimde bulunmuşsa durumu belirt
    if (name == _originalNickname) {
      isAvailable.value = true;
      if (hasUserTyped.value) {
        statusText.value = 'editor_nickname.current_name'.tr;
      } else {
        statusText.value = 'editor_nickname.edit_prompt'.tr;
      }
      return;
    }

    try {
      isChecking.value = true;
      statusText.value = 'editor_nickname.checking'.tr;

      // Global benzersizlik kontrolü
      final existing = await _userRepository.findUserByNickname(
        name,
        preferCache: true,
      );
      if (existing != null && (existing['id'] ?? '').toString() != uid) {
        isAvailable.value = false;
        statusText.value = 'editor_nickname.taken'.tr;
      } else {
        isAvailable.value = true;
        statusText.value = 'editor_nickname.available'.tr;
      }
    } catch (e) {
      isAvailable.value = null;
      statusText.value = 'editor_nickname.unavailable'.tr;
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> setData() async {
    final normalized = currentNormalized;

    // UI'da normalize edilmiş değeri sabitle
    nicknameController.value = nicknameController.value.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );

    if (normalized.length < 8) {
      AppSnackbar('common.error'.tr, 'editor_nickname.error_min_length'.tr);
      return;
    }
    try {
      final existing = await _userRepository.findUserByNickname(
        normalized,
        preferCache: true,
      );
      if (existing != null && (existing['id'] ?? '').toString() != uid) {
        throw Exception('taken');
      }

      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('changeOwnNickname')
          .call(<String, dynamic>{'nickname': normalized});

      _originalNickname = normalized;
      await _refreshNicknameSurfaces();
      await AccountCenterService.ensure().refreshCurrentAccountMetadata();
      await fetchAndSetUserData();
      Get.back();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('EditorNicknameController.setData callable error: ${e.code} ${e.message}');
      if (e.code == 'already-exists' ||
          (e.message ?? '').contains('nickname_already_taken')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_taken'.tr);
      } else if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('grace_limit')) {
        AppSnackbar(
            'common.error'.tr, 'editor_nickname.error_grace_limit'.tr);
      } else if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('cooldown')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_cooldown'.tr);
      } else if (e.code == 'invalid-argument' &&
          (e.message ?? '').contains('nickname_too_short')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_min_length'.tr);
      } else {
        AppSnackbar(
            'common.error'.tr, 'editor_nickname.error_update_failed'.tr);
      }
    } catch (e) {
      debugPrint('EditorNicknameController.setData error: $e');
      if (e.toString().contains('taken')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_taken'.tr);
      } else if (e.toString().contains('grace_limit')) {
        AppSnackbar(
            'common.error'.tr, 'editor_nickname.error_grace_limit'.tr);
      } else if (e.toString().contains('cooldown')) {
        AppSnackbar('common.error'.tr, 'editor_nickname.error_cooldown'.tr);
      } else {
        AppSnackbar(
            'common.error'.tr, 'editor_nickname.error_update_failed'.tr);
      }
    }
  }

  Future<void> _refreshNicknameSurfaces() async {
    if (Get.isRegistered<UserProfileCacheService>()) {
      await Get.find<UserProfileCacheService>().invalidateUser(uid);
    }
    PostContentController.invalidateUserProfileCache(uid);
    await CurrentUserService.instance.forceRefresh();
    await StoryRowController.refreshStoriesGlobally();
  }
}
