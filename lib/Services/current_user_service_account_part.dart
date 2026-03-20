part of 'current_user_service.dart';

extension CurrentUserServiceAccountPart on CurrentUserService {
  Future<void> restorePendingDeletionIfNeededForCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      final data = snapshot.data();
      if (data == null) return;

      final isDeleted = isDeactivatedAccount(
        accountStatus: data['accountStatus'],
        isDeleted: data['isDeleted'],
      );
      if (!isDeleted) {
        return;
      }

      final patch = <String, dynamic>{
        'accountStatus': 'active',
        'isDeleted': false,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
        'deletionRequestedAt': FieldValue.delete(),
        'deletionScheduledAt': FieldValue.delete(),
      };

      await UserRepository.ensure().updateUserFields(
        firebaseUser.uid,
        patch,
        mergeIntoCache: false,
      );

      await _applyOptimisticLocalPatch({'isDeleted': false});
      _purgeUserScopedCaches(firebaseUser.uid);
    } catch (_) {}
  }

  Future<void> updateFields(Map<String, dynamic> fields) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final normalizedFields = _normalizeUserWriteFields(fields);
      final requestedViewSelection =
          _extractRequestedViewSelection(normalizedFields);
      if (requestedViewSelection != null) {
        await _persistViewSelection(
          firebaseUser.uid,
          requestedViewSelection,
        );
        await _applyOptimisticLocalPatch({
          'viewSelection': requestedViewSelection,
        });
      }
      // Update Firestore through the central user repository.
      await UserRepository.ensure().updateUserFields(
        firebaseUser.uid,
        normalizedFields,
        mergeIntoCache: false,
      );

      await _applyOptimisticLocalPatch(normalizedFields);
      _purgeUserScopedCaches(firebaseUser.uid);
      if (Get.isRegistered<UserProfileCacheService>()) {
        await Get.find<UserProfileCacheService>().invalidateUser(
          firebaseUser.uid,
        );
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _applyOptimisticLocalPatch(
    Map<String, dynamic> normalizedFields,
  ) async {
    final current = _currentUser;
    if (current == null) return;

    bool isDeleteMarker(dynamic value) => value is FieldValue;

    String stringValue(String key, String fallback) {
      if (!normalizedFields.containsKey(key)) return fallback;
      final raw = normalizedFields[key];
      if (raw == null || isDeleteMarker(raw)) return fallback;
      return raw.toString();
    }

    int intValue(String key, int fallback) {
      if (!normalizedFields.containsKey(key)) return fallback;
      final raw = normalizedFields[key];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw == null || isDeleteMarker(raw)) return fallback;
      return int.tryParse(raw.toString()) ?? fallback;
    }

    bool boolValue(String key, bool fallback) {
      if (!normalizedFields.containsKey(key)) return fallback;
      final raw = normalizedFields[key];
      if (raw is bool) return raw;
      if (raw == null || isDeleteMarker(raw)) return fallback;
      return parseAccountFlag(raw, fallback: fallback);
    }

    String avatarValue() {
      if (!normalizedFields.containsKey('avatarUrl')) return current.avatarUrl;
      final raw = normalizedFields['avatarUrl'];
      if (raw == null || isDeleteMarker(raw)) return current.avatarUrl;
      final trimmed = raw.toString().trim();
      return isDefaultAvatarUrl(trimmed) ? '' : trimmed;
    }

    final patched = current.copyWith(
      firstName: stringValue('firstName', current.firstName),
      lastName: stringValue('lastName', current.lastName),
      nickname: stringValue('nickname', current.nickname),
      avatarUrl: avatarValue(),
      email: stringValue('email', current.email),
      phoneNumber: stringValue('phoneNumber', current.phoneNumber),
      bio: stringValue('bio', current.bio),
      rozet: stringValue(
        'rozet',
        stringValue('badge', current.rozet),
      ),
      viewSelection: intValue('viewSelection', current.viewSelection),
      counterOfFollowers:
          intValue('counterOfFollowers', current.counterOfFollowers),
      counterOfFollowings:
          intValue('counterOfFollowings', current.counterOfFollowings),
      counterOfPosts: intValue('counterOfPosts', current.counterOfPosts),
      counterOfLikes: intValue('counterOfLikes', current.counterOfLikes),
      gizliHesap: boolValue('isPrivate', current.gizliHesap),
      hesapOnayi: boolValue('isApproved', current.hesapOnayi),
    );

    await _updateUser(patched);
  }

  Map<String, dynamic> _normalizeUserWriteFields(Map<String, dynamic> input) {
    final out = <String, dynamic>{...input};

    void promoteAlias({
      required String canonical,
      required List<String> aliases,
    }) {
      if (out.containsKey(canonical)) {
        for (final alias in aliases) {
          if (out.containsKey(alias)) {
            out[alias] = FieldValue.delete();
          }
        }
        return;
      }
      for (final alias in aliases) {
        if (out.containsKey(alias)) {
          out[canonical] = out[alias];
          out[alias] = FieldValue.delete();
          break;
        }
      }
    }

    void mapRootFields({
      required String scope,
      required List<String> keys,
    }) {
      for (final key in keys) {
        if (!out.containsKey(key)) continue;
        out['$scope.$key'] = out[key];
        out[key] = FieldValue.delete();
      }
    }

    // Canonical public profile field (single source of truth: avatarUrl)
    if (!out.containsKey('displayName')) {
      final firstName = (out['firstName'] ?? '').toString().trim();
      final lastName = (out['lastName'] ?? '').toString().trim();
      final fullName =
          [firstName, lastName].where((v) => v.isNotEmpty).join(' ').trim();
      if (fullName.isNotEmpty) {
        out['displayName'] = fullName;
      } else if (out.containsKey('nickname')) {
        out['displayName'] = out['nickname'];
      }
    }
    if (out.containsKey('avatarUrl')) {
      final normalizedAvatar = (out['avatarUrl'] ?? '').toString().trim();
      out['avatarUrl'] =
          isDefaultAvatarUrl(normalizedAvatar) ? '' : normalizedAvatar;
    }
    if (out.containsKey('account.fcmToken')) {
      if (!out.containsKey('fcmToken')) {
        out['fcmToken'] = out['account.fcmToken'];
      }
      out['account.fcmToken'] = FieldValue.delete();
    }

    // Counter canonicalization (single source of truth: counterOf*)
    promoteAlias(
      canonical: 'counterOfFollowers',
      aliases: const ['followerCount', 'takipciSayisi'],
    );
    promoteAlias(
      canonical: 'counterOfFollowings',
      aliases: const ['followingCount', 'takipEdilenSayisi'],
    );
    promoteAlias(
      canonical: 'counterOfPosts',
      aliases: const ['postCount', 'gonderSayisi'],
    );

    // Move legacy root fields into scoped maps and remove root duplicates.
    mapRootFields(
      scope: 'education',
      keys: const [
        'bolum',
        'defAnaBaslik',
        'defDers',
        'defSinavTuru',
        'educationLevel',
        'fakulte',
        'lise',
        'ogrenciNo',
        'ogretimTipi',
        'okul',
        'okulIlce',
        'okulSehir',
        'ortaOkul',
        'ortalamaPuan',
        'ortalamaPuan1',
        'ortalamaPuan2',
        'osymPuanTuru',
        'osysPuan',
        'osysPuani1',
        'osysPuani2',
        'sinif',
        'universite',
        'yuzlukSistem',
      ],
    );
    mapRootFields(
      scope: 'family',
      keys: const [
        'bursVerebilir',
        'engelliRaporu',
        'evMulkiyeti',
        'familyInfo',
        'fatherJob',
        'fatherLiving',
        'fatherName',
        'fatherPhone',
        'fatherSalary',
        'fatherSurname',
        'isDisabled',
        'motherJob',
        'motherLiving',
        'motherName',
        'motherPhone',
        'motherSalary',
        'motherSurname',
        'mulkiyet',
        'totalLiving',
        'yurt',
      ],
    );

    return out;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎯 Quick Access Methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Is user blocked?
  bool isUserBlocked(String userId) {
    return _currentUser?.blockedUsers.contains(userId) ?? false;
  }

  /// Has user read story?
  bool hasReadStory(String storyId) {
    return _currentUser?.readStories.contains(storyId) ?? false;
  }

  /// Get story read time
  int? getStoryReadTime(String userId) {
    return _currentUser?.readStoriesTimes[userId];
  }

  /// Is verified account
  bool get isVerified => _currentUser?.isVerified ?? false;
  bool get isEmailVerified => emailVerifiedRx.value;

  String? _emailPromptTimestampKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return '${CurrentUserService._emailPromptTimestampKeyPrefix}:$uid';
  }

  Future<void> _loadLastEmailPromptAt() async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = _emailPromptTimestampKey();
    if (key == null) {
      _lastEmailPromptAt = null;
      return;
    }
    final raw = _prefs?.getInt(key);
    _lastEmailPromptAt =
        raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> _saveLastEmailPromptAt(DateTime value) async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = _emailPromptTimestampKey();
    if (key == null) return;
    await _prefs?.setInt(key, value.millisecondsSinceEpoch);
    _lastEmailPromptAt = value;
  }

  Future<void> _loadEmailVerifyConfig() async {
    try {
      final data = await ConfigRepository.ensure().getAdminConfigDoc(
            'emailVerify',
            preferCache: true,
            ttl: const Duration(hours: 6),
          ) ??
          const <String, dynamic>{};
      final verifyDay = data['verifyDay'];
      final days = verifyDay is num ? verifyDay.toInt() : 7;
      _emailPromptCooldown = Duration(days: days.clamp(1, 30));
    } catch (e, st) {
      _logSilently('email.verify.config', e, st);
      _emailPromptCooldown = const Duration(days: 7);
    }
  }

  Future<void> refreshEmailVerificationStatus(
      {bool reloadAuthUser = true}) async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emailVerifiedRx.value = true;
        return;
      }
      if (reloadAuthUser) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
      }
      var isVerified = user?.emailVerified ?? false;
      if (!isVerified) {
        try {
          final uid = user?.uid;
          if (uid != null && uid.isNotEmpty) {
            final data = await _readRootUserData(uid, preferCache: true);
            isVerified = data['emailVerified'] == true;
          }
        } catch (e, st) {
          _logSilently('email.verify.root-check', e, st);
        }
      }
      emailVerifiedRx.value = isVerified;
    } catch (e, st) {
      _logSilently('email.verify.refresh', e, st);
      final authVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (authVerified) {
        emailVerifiedRx.value = true;
        return;
      }
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          final data = await _readRootUserData(uid, preferCache: true);
          emailVerifiedRx.value = data['emailVerified'] == true;
          return;
        }
      } catch (inner, innerSt) {
        _logSilently('email.verify.fallback-root', inner, innerSt);
      }
      emailVerifiedRx.value = false;
    }
  }

  Future<void> sendVerificationEmailIfNeeded({bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await refreshEmailVerificationStatus(reloadAuthUser: true);
    if (!force && isEmailVerified) return;
    if (isEmailVerified) return;
    try {
      await user.sendEmailVerification();
      AppSnackbar('common.info'.tr, 'editor_email.code_sent'.tr);
    } catch (e, st) {
      _logSilently('email.verify.send', e, st);
      AppSnackbar('common.warning'.tr, 'editor_email.code_send_failed'.tr);
    }
  }

  Future<bool> ensureEmailVerifiedForRestrictedAction({
    required String actionName,
    bool showPrompt = true,
  }) async {
    await refreshEmailVerificationStatus(reloadAuthUser: true);
    if (isEmailVerified) return true;
    AppSnackbar(
      'common.info'.tr,
      'editor_email.required_for_action'.trParams({'action': actionName}),
    );
    if (showPrompt) {
      await maybeShowEmailVerificationPrompt(actionName: actionName);
    }
    return false;
  }

  Future<void> maybeShowEmailVerificationPrompt({
    String? actionName,
    bool force = false,
  }) async {
    await refreshEmailVerificationStatus(reloadAuthUser: true);
    if (isEmailVerified) return;
    await _loadLastEmailPromptAt();
    final now = DateTime.now();
    if (!force &&
        _lastEmailPromptAt != null &&
        now.difference(_lastEmailPromptAt!) < _emailPromptCooldown) {
      return;
    }
    if (Get.isDialogOpen == true) return;
    await _saveLastEmailPromptAt(now);

    await Get.dialog(
      AlertDialog(
        title: Text('editor_email.title'.tr),
        content: Text(
          actionName == null
              ? 'editor_email.dialog_body_general'.tr
              : 'editor_email.dialog_body_action'
                  .trParams({'action': actionName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common.cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await sendVerificationEmailIfNeeded(force: true);
            },
            child: Text('login.resend_code'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
