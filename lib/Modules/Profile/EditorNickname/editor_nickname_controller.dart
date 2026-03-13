import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
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
    fetchAndSetUserData();
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
    final longEnough = name.length >= 6;
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

  int? _extractGraceWindowStartAt(Map<String, dynamic> data) {
    return _parseMillis(data['nicknameGraceWindowStartAt']);
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
          cooldownText.value = 'İlk 1 saatte en fazla 3 kez değiştirilebilir';
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
          cooldownText.value =
              'Kullanıcı adı tekrar değiştirilebilir: ${days}g ${hours}s sonra';
        } else {
          cooldownText.value =
              'Kullanıcı adı tekrar değiştirilebilir: ${left.inHours}s sonra';
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
    if (name.length < 6) {
      isAvailable.value = false;
      statusText.value = 'En az 6 karakter olmalı';
      return;
    }

    // Eğer değişmemişse ama kullanıcı etkileşimde bulunmuşsa durumu belirt
    if (name == _originalNickname) {
      isAvailable.value = true;
      if (hasUserTyped.value) {
        statusText.value = 'Mevcut kullanıcı adın';
      } else {
        statusText.value = 'Değişiklik yapmak için düzenle';
      }
      return;
    }

    try {
      isChecking.value = true;
      statusText.value = 'Kontrol ediliyor…';

      // Global benzersizlik kontrolü
      final existing = await _userRepository.findUserByNickname(
        name,
        preferCache: true,
      );
      if (existing != null && (existing['id'] ?? '').toString() != uid) {
        isAvailable.value = false;
        statusText.value = 'Bu kullanıcı adı alınmış';
      } else {
        isAvailable.value = true;
        statusText.value = 'Kullanılabilir';
      }
    } catch (e) {
      isAvailable.value = null;
      statusText.value = 'Kontrol edilemedi';
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

    if (normalized.length < 6) {
      AppSnackbar('Hata', 'Kullanıcı adı en az 6 karakter olmalıdır.');
      return;
    }
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      Future<Map<String, dynamic>> buildPatch(
        Map<String, dynamic> userData,
      ) async {
        final lastChangeMs = _extractLastChangeAt(userData);
        final graceStartMs = _extractGraceWindowStartAt(userData);
        final graceCount = _extractGraceCount(userData);
        if (lastChangeMs != null) {
          final elapsed = nowMs - lastChangeMs;
          if (elapsed <= _graceWindow.inMilliseconds && graceCount >= 3) {
            throw Exception('grace_limit');
          }
          if (elapsed > _graceWindow.inMilliseconds &&
              elapsed < _changeCooldown.inMilliseconds) {
            throw Exception('cooldown');
          }
        }

        final Map<String, dynamic> userPatch = {
          'nickname': normalized,
          'username': normalized,
          'usernameLower': normalized,
          'nicknameChangedAt': nowMs,
        };

        if (_originalNickname.isNotEmpty && _originalNickname != normalized) {
          final historyEntry = {
            'nickname': _originalNickname,
            'changedAt': nowMs,
            'to': normalized,
          };
          final existingOld = userData['oldNicknames'];
          final existingHistory = userData['nicknameHistory'];

          if (existingOld is List) {
            userPatch['oldNicknames'] =
                FieldValue.arrayUnion([_originalNickname]);
          } else {
            userPatch['oldNicknames'] = [_originalNickname];
          }

          if (existingHistory is List) {
            userPatch['nicknameHistory'] =
                FieldValue.arrayUnion([historyEntry]);
          } else {
            userPatch['nicknameHistory'] = [historyEntry];
          }
        }

        // İlk 1 saat içinde en fazla 3 değişiklik limiti
        final inGrace = lastChangeMs != null &&
            (nowMs - lastChangeMs) <= _graceWindow.inMilliseconds;
        if (inGrace) {
          final windowStart = graceStartMs ?? lastChangeMs;
          final currentCount = graceCount <= 0 ? 1 : graceCount;
          final nextCount = currentCount + 1;
          userPatch['nicknameGraceWindowStartAt'] = windowStart;
          userPatch['nicknameGraceChangeCount'] = nextCount;
        } else {
          userPatch['nicknameGraceWindowStartAt'] = nowMs;
          userPatch['nicknameGraceChangeCount'] = 1;
        }

        return userPatch;
      }

      // 1) Uniqueness check (users koleksiyonu)
      final existing = await _userRepository.findUserByNickname(
        normalized,
        preferCache: true,
      );
      if (existing != null && (existing['id'] ?? '').toString() != uid) {
        throw Exception('taken');
      }

      // 2) Primary path: transaction
      try {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final userSnap = await tx.get(userDoc);
          final patch = await buildPatch(
            userSnap.data() ?? const <String, dynamic>{},
          );
          tx.update(userDoc, patch);
        });
      } catch (txError) {
        // 3) Fallback: direct update (bazı rule/registry uyumsuzlukları için)
        debugPrint('Nickname tx fallback: $txError');
        final freshData = await _userRepository.getUserRaw(
          uid,
          preferCache: false,
          cacheOnly: false,
          forceServer: true,
        );
        final patch = await buildPatch(freshData ?? const <String, dynamic>{});
        await userDoc.update(patch);
      }

      _originalNickname = normalized;
      await _refreshNicknameSurfaces();
      await fetchAndSetUserData();
      Get.back();
    } catch (e) {
      debugPrint('EditorNicknameController.setData error: $e');
      if (e.toString().contains('taken')) {
        AppSnackbar('Hata', 'Bu kullanıcı adı zaten alınmış.');
      } else if (e.toString().contains('grace_limit')) {
        AppSnackbar('Hata', 'İlk 1 saatte en fazla 3 kez değiştirebilirsin.');
      } else if (e.toString().contains('cooldown')) {
        AppSnackbar(
            'Hata', 'Kullanıcı adı 15 gün dolmadan tekrar değiştirilemez.');
      } else {
        AppSnackbar('Hata', 'Kullanıcı adı güncellenemedi.');
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
