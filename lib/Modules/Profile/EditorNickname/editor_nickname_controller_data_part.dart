part of 'editor_nickname_controller.dart';

extension EditorNicknameControllerDataPart on EditorNicknameController {
  void _handleOnInit() {
    _seedFromCurrentUser();
    unawaited(fetchAndSetUserData());
    nicknameController.addListener(_onTextChanged);
  }

  void _handleOnClose() {
    _debounce?.cancel();
    nicknameController.removeListener(_onTextChanged);
    nicknameController.dispose();
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
      _originalNickname = nickname;
      _updateCooldownState(data);
      _triggerDebouncedCheck();
    }
  }

  void _onTextChanged() {
    final currentText = nicknameController.text;
    final norm = normalizeEditableNickname(currentText);

    if (currentText.isNotEmpty && currentText != _originalNickname) {
      hasUserTyped.value = true;
    }

    if (currentText != norm) {
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

    if (lastChangeMs != null) {
      final elapsed = nowMs - lastChangeMs;
      if (elapsed <= EditorNicknameController._graceWindow.inMilliseconds) {
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
      if (elapsed < EditorNicknameController._changeCooldown.inMilliseconds) {
        final left = Duration(
          milliseconds:
              EditorNicknameController._changeCooldown.inMilliseconds - elapsed,
        );
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

    final withinSignupGrace = createdAtMs != null &&
        (nowMs - createdAtMs) <=
            EditorNicknameController._graceWindow.inMilliseconds;
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
    } catch (_) {
      isAvailable.value = null;
      statusText.value = 'editor_nickname.unavailable'.tr;
    } finally {
      isChecking.value = false;
    }
  }
}
